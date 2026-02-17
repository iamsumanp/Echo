import AppKit
import Combine

class ClipboardMonitor: ObservableObject {
    private var timer: Timer?
    private var lastChangeCount: Int
    private let pasteboard = NSPasteboard.general
    private weak var historyManager: HistoryManager?

    init(historyManager: HistoryManager) {
        self.historyManager = historyManager
        self.lastChangeCount = pasteboard.changeCount
    }

    func startMonitoring() {
        // Check for clipboard changes every 0.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // Attempt to identify the application the user copied from.
        // This assumes the frontmost application is the source.
        let frontmostApp = NSWorkspace.shared.frontmostApplication
        let appName = frontmostApp?.localizedName
        let bundleIdentifier = frontmostApp?.bundleIdentifier

        // Check for text
        if let string = pasteboard.string(forType: .string) {
            // Ignore empty strings or strings that are just whitespace
            if !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                historyManager?.addText(string, from: appName, bundleIdentifier: bundleIdentifier)
            }
        }
        // Check for images
        else if NSImage.canInit(with: pasteboard) {
            // Try to get image data
            if let image = NSImage(pasteboard: pasteboard),
                let tiffData = image.tiffRepresentation,
                let bitmap = NSBitmapImageRep(data: tiffData),
                let pngData = bitmap.representation(using: .png, properties: [:])
            {
                historyManager?.addImage(pngData, from: appName, bundleIdentifier: bundleIdentifier)
            }
        }
    }
}
