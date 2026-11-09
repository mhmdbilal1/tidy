import AppKit
import Foundation

nonisolated enum FolderIconManager {
    private static let symbols: [String: String] = [
        "Invoices & Receipts": "receipt",
        "School": "graduationcap.fill",
        "Cars": "car.fill",
        "Resume & Career": "briefcase.fill",
        "Code": "chevron.left.forwardslash.chevron.right",
        "Finance": "dollarsign.circle.fill",
        "Travel": "airplane",
        "Photos - People & Pets": "person.2.fill",
        "Photos - Nature": "leaf.fill",
        "Images": "photo.fill",
        "Documents": "doc.text.fill",
        "Spreadsheets": "tablecells.fill",
        "Presentations": "rectangle.on.rectangle",
        "Videos": "film.fill",
        "Audio": "waveform",
        "Archives": "archivebox.fill",
        "Unsorted": "tray.fill"
    ]

    private static let colors: [String: NSColor] = [
        "Invoices & Receipts": NSColor.systemOrange,
        "School": NSColor.systemIndigo,
        "Cars": NSColor.systemRed,
        "Resume & Career": NSColor.systemPurple,
        "Code": NSColor.systemGreen,
        "Finance": NSColor.systemGreen,
        "Travel": NSColor.systemTeal,
        "Photos - People & Pets": NSColor.systemPink,
        "Photos - Nature": NSColor.systemGreen,
        "Images": NSColor.systemPink,
        "Documents": NSColor.systemBlue,
        "Spreadsheets": NSColor.systemGreen,
        "Presentations": NSColor.systemOrange,
        "Videos": NSColor.systemRed,
        "Audio": NSColor.systemPurple,
        "Archives": NSColor.systemBrown,
        "Unsorted": NSColor.systemGray
    ]

    private static let aliases: [(String, String)] = [
        ("invoice", "Invoices & Receipts"), ("receipt", "Invoices & Receipts"),
        ("bill", "Invoices & Receipts"), ("school", "School"),
        ("class", "School"), ("education", "School"), ("car", "Cars"),
        ("vehicle", "Cars"), ("resume", "Resume & Career"),
        ("career", "Resume & Career"), ("job", "Resume & Career"),
        ("code", "Code"), ("finance", "Finance"), ("tax", "Finance"),
        ("bank", "Finance"), ("travel", "Travel"), ("trip", "Travel"),
        ("vacation", "Travel"), ("people", "Photos - People & Pets"),
        ("family", "Photos - People & Pets"), ("pet", "Photos - People & Pets"),
        ("nature", "Photos - Nature"), ("photo", "Images"), ("image", "Images"),
        ("document", "Documents"), ("spreadsheet", "Spreadsheets"),
        ("presentation", "Presentations"), ("video", "Videos"),
        ("audio", "Audio"), ("music", "Audio"), ("archive", "Archives"),
        ("zip", "Archives"), ("unsorted", "Unsorted")
    ]

    static func apply(to folder: URL) -> Bool {
        let category = folder.lastPathComponent
        let normalized = category.lowercased()
        let matchedCategory = symbols[category] != nil ? category :
            aliases.first(where: { normalized.contains($0.0) })?.1
        guard let matchedCategory, let symbolName = symbols[matchedCategory],
              let icon = makeFolderIcon(symbolName: symbolName,
                                        color: colors[matchedCategory] ?? .systemBlue,
                                        description: category) else {
            return false
        }
        return NSWorkspace.shared.setIcon(icon, forFile: folder.path, options: [])
    }

    private static func makeFolderIcon(symbolName: String, color: NSColor,
                                       description: String) -> NSImage? {
        guard let mark = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 88, weight: .semibold)) else {
            return nil
        }

        let size = NSSize(width: 512, height: 512)
        let image = NSImage(size: size, flipped: false) { _ in
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
            shadow.shadowBlurRadius = 18
            shadow.shadowOffset = NSSize(width: 0, height: -8)
            shadow.set()

            let tab = NSBezierPath(roundedRect: NSRect(x: 48, y: 330, width: 208, height: 104),
                                   xRadius: 32, yRadius: 32)
            let front = NSBezierPath(roundedRect: NSRect(x: 34, y: 74, width: 444, height: 322),
                                     xRadius: 52, yRadius: 52)
            let gradient = NSGradient(starting: color.blended(withFraction: 0.24, of: NSColor.white) ?? color,
                                      ending: color.blended(withFraction: 0.12, of: NSColor.black) ?? color)!
            gradient.draw(in: tab, angle: 90)
            gradient.draw(in: front, angle: 90)
            NSShadow().set()

            let badge = NSRect(x: 190, y: 168, width: 132, height: 132)
            let badgePath = NSBezierPath(roundedRect: badge, xRadius: 38, yRadius: 38)
            NSColor.white.withAlphaComponent(0.96).setFill()
            badgePath.fill()
            let markRect = NSRect(x: badge.midX - 48, y: badge.midY - 48, width: 96, height: 96)
            mark.draw(in: markRect, from: .zero, operation: .sourceOver, fraction: 1)
            let context = NSGraphicsContext.current?.cgContext
            context?.saveGState()
            context?.setBlendMode(.sourceAtop)
            color.setFill()
            NSBezierPath(rect: markRect).fill()
            context?.restoreGState()
            return true
        }
        image.isTemplate = false
        return image
    }
}
