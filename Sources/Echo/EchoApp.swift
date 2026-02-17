import AppKit
import SwiftUI

@main
struct EchoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManager: WindowManager<AnyView>?
    let dependencies = AppDependencies()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy to accessory to hide dock icon while maintaining searchability
        NSApp.setActivationPolicy(.accessory)

        // Create the content view with dependencies injected
        let contentView = ContentView()
            .environmentObject(dependencies.historyManager)

        // Initialize the window manager which handles the status item and window creation
        windowManager = WindowManager(rootView: AnyView(contentView))

        HotKeyManager.shared.register { [weak self] in
            self?.windowManager?.toggleWindow()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.unregister()
    }
}

class AppDependencies: ObservableObject {
    let historyManager: HistoryManager
    let clipboardMonitor: ClipboardMonitor

    init() {
        self.historyManager = HistoryManager()
        self.clipboardMonitor = ClipboardMonitor(historyManager: self.historyManager)
        self.clipboardMonitor.startMonitoring()
    }
}
