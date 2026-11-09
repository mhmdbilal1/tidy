import Foundation

nonisolated enum NameSuggester {
    private static let genericPrefixes = [
        "untitled", "new document", "document", "scanned", "scan", "screenshot",
        "screen shot", "img", "image", "photo", "picture", "file", "download",
        "attachment", "dsc", "pxl"
    ]

    private static let documentTypes: [(String, [String])] = [
        ("Payment Confirmation", ["payment confirmation", "payment successful", "payment received", "transaction approved"]),
        ("Boarding Pass", ["boarding pass", "passenger", "flight number"]),
        ("Bank Statement", ["bank statement", "statement period", "account summary"]),
        ("Utility Bill", ["hydro one", "utility bill", "electricity bill", "water bill", "gas bill"]),
        ("Tax Document", ["notice of assessment", "tax return", "tax year"]),
        ("Invoice", ["invoice number", "invoice #", "amount due", "bill to"]),
        ("Receipt", ["receipt", "amount paid", "payment method", "subtotal"]),
        ("Insurance Document", ["insurance policy", "policy number", "coverage details"]),
        ("Lease Agreement", ["lease agreement", "rental agreement"]),
        ("Travel Booking", ["flight confirmation", "booking confirmation", "reservation confirmation"])
    ]

    static func suggestedFilename(for url: URL, content: String) -> String? {
        let baseName = url.deletingPathExtension().lastPathComponent
        guard isGeneric(baseName) else { return nil }
        guard let title = suggestedTitle(from: content) else { return nil }

        let safeTitle = title
            .components(separatedBy: CharacterSet(charactersIn: "/\\:"))
            .joined(separator: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard safeTitle.count >= 3 else { return nil }

        return url.pathExtension.isEmpty ? safeTitle : "\(safeTitle).\(url.pathExtension)"
    }

    private static func isGeneric(_ name: String) -> Bool {
        let normalized = name.lowercased().replacingOccurrences(of: "[_-]", with: " ", options: .regularExpression)
        for prefix in genericPrefixes {
            guard normalized == prefix || normalized.hasPrefix(prefix + " ") else { continue }
            let suffix = normalized.dropFirst(prefix.count)
            if suffix.allSatisfy({ $0.isNumber || $0.isWhitespace || "().-at".contains($0) }) {
                return true
            }
        }
        return false
    }

    private static func suggestedTitle(from content: String) -> String? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lower = trimmed.lowercased()
        if let match = documentTypes.first(where: { _, cues in cues.contains(where: lower.contains) }) {
            return match.0
        }

        let excluded = ["page ", "www.", "http", "account number", "reference number", "transaction id", "phone", "email", "address", "subtotal", "amount due"]
        for rawLine in trimmed.components(separatedBy: .newlines).prefix(12) {
            let line = rawLine
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            let lineLower = line.lowercased()
            let letterCount = line.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
            guard line.count >= 4, line.count <= 48, letterCount >= 4,
                  !excluded.contains(where: lineLower.contains),
                  !line.contains("@") else { continue }
            return line.capitalized
        }
        return nil
    }
}
