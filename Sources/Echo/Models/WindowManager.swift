import AppKit
import SwiftUI

class WindowManager<Content: View>: NSObject, NSWindowDelegate {
    private var window: BorderlessWindow!
    private var statusItem: NSStatusItem!
    private let rootView: Content

    init(rootView: Content) {
        self.rootView = rootView
        super.init()
        setupStatusItem()
        // Defer window creation to first use or applicationDidFinishLaunching
        DispatchQueue.main.async {
            self.setupWindow()
        }
    }

    private func setupWindow() {
        // Create a borderless window
        window = BorderlessWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 450),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // Window appearance
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Set content view hosted in NSHostingView
        let hostingView = NSHostingView(
            rootView:
                rootView
                .edgesIgnoringSafeArea(.all)
        )
        window.contentView = hostingView

        // Delegate for focus handling
        window.delegate = self
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard Manager")
            button.action = #selector(handleStatusItemClick(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc func handleStatusItemClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            let menu = NSMenu()

            let showItem = NSMenuItem(
                title: "Show Clipboard History", action: #selector(toggleWindow), keyEquivalent: "")
            showItem.target = self
            menu.addItem(showItem)

            let prefsItem = NSMenuItem(
                title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
            prefsItem.target = self
            menu.addItem(prefsItem)

            menu.addItem(NSMenuItem.separator())

            let quitItem = NSMenuItem(
                title: "Quit Clipboard Manager", action: #selector(terminateApp), keyEquivalent: "q"
            )
            quitItem.target = self
            menu.addItem(quitItem)

            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
        } else {
            toggleWindow()
        }
    }

    @objc func terminateApp() {
        NSApp.terminate(nil)
    }

    @objc func openPreferences() {
        if window == nil || !window.isVisible {
            show()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
        NotificationCenter.default.post(name: .openPreferences, object: nil)
    }

    @objc func toggleWindow() {
        if window != nil && window.isVisible && window.isKeyWindow {
            close()
        } else {
            show()
        }
    }

    func show() {
        // Ensure window is created
        if window == nil { setupWindow() }

        // Position on the screen where the mouse cursor is
        centerOnActiveScreen()

        // Bring to front and activate
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        // Hiding the app returns focus to the previous application
        NSApp.hide(nil)
    }

    /// Centers the window on whichever screen the mouse cursor is currently on
    private func centerOnActiveScreen() {
        let mouseLocation = NSEvent.mouseLocation

        // Find the screen that contains the mouse cursor
        let activeScreen = NSScreen.screens.first(where: { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        }) ?? NSScreen.main ?? NSScreen.screens.first

        guard let screen = activeScreen else { return }

        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size

        let x = screenFrame.midX - (windowSize.width / 2)
        let y = screenFrame.midY - (windowSize.height / 2)

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - NSWindowDelegate

    func windowDidResignKey(_ notification: Notification) {
        // Don't close if a sheet (e.g. Settings) is being presented
        guard window.sheets.isEmpty else { return }
        // Automatically close when focus is lost (clicking outside)
        close()
    }
}

// Subclass NSWindow to allow borderless window to become key
class BorderlessWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}

extension Notification.Name {
    static let openPreferences = Notification.Name("OpenPreferences")
}
