import Foundation

nonisolated enum Safety {
    static let blockedPrefixes = ["/System", "/Library", "/usr", "/bin", "/sbin",
                                  "/private", "/Applications", "/Volumes", "/opt"]
    static let blockedExtensions: Set<String> = [
        "app", "plist", "dylib", "kext", "framework", "pkg", "dmg", "photoslibrary",
        "musiclibrary", "xcodeproj", "xcworkspace", "sqlite", "db", "icloud", "crdownload",
        "download", "part", "tmp"
    ]

    static func isSafeToMove(_ url: URL, root: URL) -> Bool {
        let path = url.standardizedFileURL.path
        if blockedPrefixes.contains(where: { path.hasPrefix($0) }) { return false }
        if !path.hasPrefix(root.standardizedFileURL.path) { return false }
        if url.lastPathComponent.hasPrefix(".") { return false }
        if blockedExtensions.contains(url.pathExtension.lowercased()) { return false }
        let keys: Set<URLResourceKey> = [.isPackageKey, .isSymbolicLinkKey, .isRegularFileKey,
                                         .contentModificationDateKey]
        guard let v = try? url.resourceValues(forKeys: keys) else { return false }
        if v.isPackage == true || v.isSymbolicLink == true { return false }
        if v.isRegularFile != true { return false }
        if let m = v.contentModificationDate, Date().timeIntervalSince(m) < 60 { return false }
        return true
    }
}
