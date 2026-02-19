import Combine
import SwiftUI

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, NSImage>()

    private init() {
        cache.countLimit = 50
        cache.totalCostLimit = 100 * 1024 * 1024  // 100 MB
    }

    func image(for url: URL) -> NSImage? {
        return cache.object(forKey: url as NSURL)
    }

    func insert(_ image: NSImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

struct CachedImage: View {
    let url: URL

    @State private var image: NSImage?
    @State private var isLoading = false

    var body: some View {
        GeometryReader { geo in
            Group {
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    ZStack {
                        Color.secondary.opacity(0.1)
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        // Check cache first
        if let cached = ImageCache.shared.image(for: url) {
            self.image = cached
            return
        }

        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            // Load image from disk
            if let loadedImage = NSImage(contentsOf: url) {
                // Cache it
                ImageCache.shared.insert(loadedImage, for: url)

                DispatchQueue.main.async {
                    self.image = loadedImage
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}
