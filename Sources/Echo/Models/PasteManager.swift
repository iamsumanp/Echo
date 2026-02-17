import AppKit
import Carbon

class PasteManager {
    static let shared = PasteManager()

    private init() {}

    func paste() {
        // Hide the ClipboardManager window so focus returns to the previous app
        NSApp.hide(nil)

        // Wait briefly for the previous app to become active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulateCommandV()
        }
    }

    private func simulateCommandV() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key code for 'v' is 9
        let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)

        // Add Command modifier flag
        vKeyDown?.flags = .maskCommand
        vKeyUp?.flags = .maskCommand

        vKeyDown?.post(tap: .cghidEventTap)
        vKeyUp?.post(tap: .cghidEventTap)
    }

    func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
