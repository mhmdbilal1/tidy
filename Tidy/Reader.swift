import Foundation
import PDFKit
import Vision

nonisolated enum Reader {
    static func text(from url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "pdf":
            return String((PDFDocument(url: url)?.string ?? "").prefix(3000))
        case "txt", "md", "swift", "java", "py", "csv", "json", "html", "js", "c", "cpp":
            return String(((try? String(contentsOf: url, encoding: .utf8)) ?? "").prefix(3000))
        case "jpg", "jpeg", "png", "heic", "tiff":
            return imageLabels(url) + "\n" + imageText(url)
        default:
            return ""
        }
    }

    static func imageLabels(_ url: URL) -> String {
        let req = VNClassifyImageRequest()
        try? VNImageRequestHandler(url: url).perform([req])
        return (req.results ?? [])
            .filter { $0.confidence > 0.3 }
            .prefix(5)
            .map { $0.identifier }
            .joined(separator: " ")
    }

    static func imageText(_ url: URL) -> String {
        let req = VNRecognizeTextRequest()
        req.recognitionLevel = .fast
        try? VNImageRequestHandler(url: url).perform([req])
        let s = (req.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")
        return String(s.prefix(1000))
    }
}
