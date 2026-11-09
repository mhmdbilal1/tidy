import AppKit
import Foundation
import SwiftUI
import Combine

struct MoveRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let from: URL
    var to: URL
    var reason: String
}

@MainActor
final class Organizer: ObservableObject {
    @Published var plan: [MoveRecord] = []
    @Published var history: [[MoveRecord]] = []
    @Published var status = "Choose a folder to begin."
    @Published var isScanning = false

    private let classifier = Classifier()

    private var logURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Tidy/journal.json")
    }

    init() { load() }

    func buildPlan(root: URL) {
        isScanning = true
        plan = []
        status = "Scanning..."
        let classifier = self.classifier
        Task.detached {
            let fm = FileManager.default
            let items = (try? fm.contentsOfDirectory(
                at: root, includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsPackageDescendants])) ?? []
            let existingFolders = items.filter { url in
                guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .isPackageKey]) else { return false }
                return values.isDirectory == true && values.isSymbolicLink != true && values.isPackage != true
            }
            var out: [MoveRecord] = []
            for url in items where Safety.isSafeToMove(url, root: root) {
                let text = Reader.text(from: url)
                let result: (folder: String, reason: String)
                if text.isEmpty {
                    result = (Organizer.extensionCategory(url), "file type")
                } else {
                    result = classifier.classify(text)
                }
                let suggestedName = NameSuggester.suggestedFilename(for: url, content: text)
                let destinationName = suggestedName ?? url.lastPathComponent
                let dest = root.appendingPathComponent(result.folder)
                    .appendingPathComponent(destinationName)
                out.append(MoveRecord(id: UUID(), from: url, to: dest, reason: result.reason))
            }
            let final = out
            await MainActor.run {
                let refreshedIcons = existingFolders.reduce(into: 0) { count, folder in
                    if FolderIconManager.apply(to: folder) { count += 1 }
                }
                self.plan = final
                self.isScanning = false
                let renameCount = final.filter { $0.from.lastPathComponent != $0.to.lastPathComponent }.count
                self.status = final.isEmpty
                    ? "Nothing to organize. Updated icons for \(refreshedIcons) folders."
                    : "\(final.count) files ready · \(renameCount) name suggestions · updated \(refreshedIcons) folder icons. Review, then Organize."
            }
        }
    }

    nonisolated static func extensionCategory(_ url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "jpg", "jpeg", "png", "heic", "gif", "tiff", "webp": return "Images"
        case "pdf", "doc", "docx", "txt", "pages", "rtf": return "Documents"
        case "xls", "xlsx", "csv", "numbers": return "Spreadsheets"
        case "ppt", "pptx", "key": return "Presentations"
        case "mp4", "mov", "mkv", "avi": return "Videos"
        case "mp3", "wav", "m4a", "flac": return "Audio"
        case "zip", "rar", "7z", "tar", "gz": return "Archives"
        case "swift", "java", "py", "js", "c", "cpp", "html", "css": return "Code"
        default: return "Unsorted"
        }
    }

    func skip(_ record: MoveRecord) {
        plan.removeAll { $0.id == record.id }
    }

    func apply() {
        let fm = FileManager.default
        var done: [MoveRecord] = []
        for var r in plan {
            do {
                let destinationFolder = r.to.deletingLastPathComponent()
                try fm.createDirectory(at: destinationFolder,
                                       withIntermediateDirectories: true)
                FolderIconManager.apply(to: destinationFolder)
                r.to = uniqueURL(r.to)
                try fm.moveItem(at: r.from, to: r.to)
                done.append(r)
            } catch {
                continue
            }
        }
        if !done.isEmpty { history.append(done) }
        plan = []
        status = "Organized \(done.count) files. You can undo."
        save()
    }

    func undoLast() {
        guard let batch = history.popLast() else { return }
        let fm = FileManager.default
        var restored = 0
        for r in batch.reversed() {
            guard fm.fileExists(atPath: r.to.path), !fm.fileExists(atPath: r.from.path) else { continue }
            if (try? fm.moveItem(at: r.to, to: r.from)) != nil { restored += 1 }
            let folder = r.to.deletingLastPathComponent()
            if let left = try? fm.contentsOfDirectory(atPath: folder.path),
               left.allSatisfy({ $0 == ".DS_Store" }) {
                try? fm.removeItem(at: folder)
            }
        }
        status = "Undid last batch: restored \(restored) files."
        save()
    }

    private func uniqueURL(_ url: URL) -> URL {
        var candidate = url
        var i = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            let name = url.deletingPathExtension().lastPathComponent
            candidate = url.deletingLastPathComponent()
                .appendingPathComponent("\(name) \(i)")
                .appendingPathExtension(url.pathExtension)
            i += 1
        }
        return candidate
    }

    private func save() {
        try? FileManager.default.createDirectory(
            at: logURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(history) { try? data.write(to: logURL) }
    }

    private func load() {
        guard let data = try? Data(contentsOf: logURL),
              let h = try? JSONDecoder().decode([[MoveRecord]].self, from: data) else { return }
        history = h
    }
}
