import AppKit

class AppIconProvider {
    static let shared = AppIconProvider()

    private var cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 100
    }

    func getIcon(for bundleIdentifier: String) -> NSImage? {
        // Check cache first
        if let cached = cache.object(forKey: bundleIdentifier as NSString) {
            return cached
        }

        // Try to find the application URL
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            // Cache the result
            cache.setObject(icon, forKey: bundleIdentifier as NSString)
            return icon
        }

        return nil
    }
}
