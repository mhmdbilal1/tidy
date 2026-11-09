import AppKit
import SwiftUI

@main
struct TidyApp: App {
    @NSApplicationDelegateAdaptor(TidyAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentMinSize)
    }
}

private final class TidyAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        if let icon = NSImage(named: NSImage.Name("AppIcon")) {
            app.applicationIconImage = icon
        }
        app.activate(ignoringOtherApps: true)
    }
}
