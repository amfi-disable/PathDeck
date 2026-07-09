import SwiftUI
import AppKit

/// Application delegate hook to terminate application immediately after main window is closed.
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

/// Entry point for the PathDeck native macOS application.
@main
struct PathDeckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    // Instantiate our central state coordinator
    @State private var service = ShellConfigService()
    
    @Environment(\.openWindow) private var openWindow
    
    init() {
        // Make the app a regular foreground GUI app, enabling dock icon and window focus
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    var body: some Scene {
        WindowGroup("PathDeck Studio") {
            MainView()
                .environment(service)
                .preferredColorScheme(.dark) // Dark developer studio aesthetic
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Customize Help menu to trigger manual view window
            CommandGroup(replacing: .help) {
                Button("PathDeck Help Manual") {
                    openWindow(id: "help-manual")
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
        
        // Help Manual Window Group
        Window("PathDeck Help Manual", id: "help-manual") {
            HelpView()
                .preferredColorScheme(.dark)
        }
    }
}
