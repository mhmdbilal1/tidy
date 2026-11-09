import Foundation
import NaturalLanguage

nonisolated final class Classifier: @unchecked Sendable {
    private let embedding = NLEmbedding.sentenceEmbedding(for: .english)

    // Edit these to add your own topics. Keywords are lowercase.
    let topics: [String: [String]] = [
        "Invoices & Receipts": ["invoice", "receipt", "payment", "total", "amount due", "tax", "subtotal", "order number"],
        "School": ["assignment", "lecture", "course", "exam", "university", "syllabus", "midterm", "professor", "lab"],
        "Cars": ["engine", "oil", "brake", "vehicle", "repair", "tuning", "torque", "obd", "transmission"],
        "Resume & Career": ["resume", "experience", "skills", "education", "cover letter", "references", "employment"],
        "Code": ["function", "class", "import", "variable", "compile", "public static", "def ", "return"],
        "Finance": ["bank", "statement", "balance", "account", "loan", "mortgage", "investment", "tax return"],
        "Travel": ["flight", "boarding", "hotel", "reservation", "itinerary", "passport", "booking"],
        "Photos - People & Pets": ["person", "people", "dog", "cat", "portrait", "face"],
        "Photos - Nature": ["landscape", "mountain", "tree", "sky", "beach", "flower", "water"]
    ]

    func classify(_ text: String) -> (folder: String, reason: String) {
        let lower = text.lowercased()
        guard lower.count > 15 else { return ("Unsorted", "not enough content") }

        var bestKeyword: (String, Int) = ("", 0)
        for (name, words) in topics {
            let hits = words.filter { lower.contains($0) }.count
            if hits > bestKeyword.1 { bestKeyword = (name, hits) }
        }
        if bestKeyword.1 >= 2 { return (bestKeyword.0, "\(bestKeyword.1) keyword matches") }

        if let e = embedding {
            let sample = String(lower.prefix(500))
            var best: (String, Double) = ("", 2.0)
            for (name, words) in topics {
                let d = e.distance(between: sample, and: words.joined(separator: " "))
                if d < best.1 { best = (name, d) }
            }
            if best.1 < 1.15 { return (best.0, String(format: "semantic match (%.2f)", best.1)) }
        }
        if bestKeyword.1 == 1 { return (bestKeyword.0, "1 keyword match") }
        return ("Unsorted", "no confident match")
    }
}
