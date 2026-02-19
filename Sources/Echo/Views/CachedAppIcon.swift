import SwiftUI

struct CachedAppIcon: View {
    let bundleIdentifier: String
    let size: CGFloat

    @State private var icon: NSImage?

    init(bundleIdentifier: String, size: CGFloat = 32) {
        self.bundleIdentifier = bundleIdentifier
        self.size = size
    }

    var body: some View {
        Group {
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "app.dashed")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if icon == nil {
                DispatchQueue.global(qos: .userInitiated).async {
                    let loadedIcon = AppIconProvider.shared.getIcon(for: bundleIdentifier)
                    DispatchQueue.main.async {
                        self.icon = loadedIcon
                    }
                }
            }
        }
    }
}
