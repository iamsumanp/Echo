import Combine
import Foundation

class HistoryManager: ObservableObject {
    @Published var items: [ClipboardItem] = []

    private let historyFileName = "clipboard_history.json"
    private let imagesDirectoryName = "clipboard_images"

    var retentionDays: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: "retentionDays")
            return val == 0 ? 30 : val
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "retentionDays")
            pruneOldItems()
        }
    }

    private var dataDirectory: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Echo")
    }

    private var historyFileURL: URL? {
        dataDirectory?.appendingPathComponent(historyFileName)
    }

    private var imagesDirectoryURL: URL? {
        dataDirectory?.appendingPathComponent(imagesDirectoryName)
    }

    init() {
        createDirectories()
        loadHistory()
        pruneOldItems()
    }

    private func createDirectories() {
        guard let dataDirectory = dataDirectory, let imagesDirectoryURL = imagesDirectoryURL else {
            return
        }

        do {
            if !FileManager.default.fileExists(atPath: dataDirectory.path) {
                try FileManager.default.createDirectory(
                    at: dataDirectory, withIntermediateDirectories: true)
            }
            if !FileManager.default.fileExists(atPath: imagesDirectoryURL.path) {
                try FileManager.default.createDirectory(
                    at: imagesDirectoryURL, withIntermediateDirectories: true)
            }
        } catch {
            print("Error creating directories: \(error)")
        }
    }

    func loadHistory() {
        guard let historyFileURL = historyFileURL,
            FileManager.default.fileExists(atPath: historyFileURL.path)
        else { return }

        do {
            let data = try Data(contentsOf: historyFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            items = try decoder.decode([ClipboardItem].self, from: data)
            // Sort by date descending
            items.sort { $0.dateCreated > $1.dateCreated }
        } catch {
            print("Error loading history: \(error)")
        }
    }

    func saveHistory() {
        guard let historyFileURL = historyFileURL else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(items)
            try data.write(to: historyFileURL)
        } catch {
            print("Error saving history: \(error)")
        }
    }

    func addText(_ text: String, from appName: String?, bundleIdentifier: String?) {
        if text.isEmpty { return }

        // Check for duplicates
        if let index = items.firstIndex(where: { $0.type == .text && $0.textContent == text }) {
            let existing = items[index]
            items.remove(at: index)

            let newItem = ClipboardItem(
                id: existing.id,  // Reuse ID? Or new ID? Let's use new ID to reflect fresh copy but keep pin state
                textContent: text,
                imagePath: nil,
                type: .text,
                dateCreated: Date(),
                isPinned: existing.isPinned,
                applicationName: appName,
                bundleIdentifier: bundleIdentifier
            )
            items.insert(newItem, at: 0)
        } else {
            let newItem = ClipboardItem(
                textContent: text,
                type: .text,
                applicationName: appName,
                bundleIdentifier: bundleIdentifier
            )
            items.insert(newItem, at: 0)
        }

        saveHistory()
    }

    func addImage(_ data: Data, from appName: String?, bundleIdentifier: String?) {
        guard let filename = saveImageToDisk(data) else { return }

        let newItem = ClipboardItem(
            textContent: nil,
            imagePath: filename,
            type: .image,
            applicationName: appName,
            bundleIdentifier: bundleIdentifier
        )
        items.insert(newItem, at: 0)
        saveHistory()
    }

    func togglePin(for id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isPinned.toggle()
            saveHistory()
        }
    }

    func deleteItem(id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            let item = items[index]
            deleteImageFile(for: item)
            items.remove(at: index)
            saveHistory()
        }
    }

    func clearUnpinnedHistory() {
        let pinnedItems = items.filter { $0.isPinned }
        let unpinnedItems = items.filter { !$0.isPinned }

        for item in unpinnedItems {
            deleteImageFile(for: item)
        }

        items = pinnedItems
        saveHistory()
    }

    func pruneOldItems() {
        guard
            let cutoffDate = Calendar.current.date(
                byAdding: .day, value: -retentionDays, to: Date())
        else { return }

        let itemsToKeep = items.filter { $0.isPinned || $0.dateCreated >= cutoffDate }
        let itemsToRemove = items.filter { !$0.isPinned && $0.dateCreated < cutoffDate }

        for item in itemsToRemove {
            deleteImageFile(for: item)
        }

        if items.count != itemsToKeep.count {
            items = itemsToKeep
            saveHistory()
        }
    }

    private func saveImageToDisk(_ data: Data) -> String? {
        guard let imagesDirectoryURL = imagesDirectoryURL else { return nil }

        let filename = UUID().uuidString + ".png"  // Assuming PNG for simplicity
        let fileURL = imagesDirectoryURL.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return filename
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }

    private func deleteImageFile(for item: ClipboardItem) {
        guard let imagePath = item.imagePath, let imagesDir = imagesDirectoryURL else { return }
        let fileURL = imagesDir.appendingPathComponent(imagePath)
        try? FileManager.default.removeItem(at: fileURL)
    }

    func getImageUrl(for filename: String) -> URL? {
        return imagesDirectoryURL?.appendingPathComponent(filename)
    }
}
