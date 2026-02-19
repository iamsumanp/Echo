import Foundation

enum ClipboardItemType: String, Codable {
    case text
    case image
}

struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID
    let textContent: String?
    let imagePath: String?
    let type: ClipboardItemType
    let dateCreated: Date
    var isPinned: Bool
    var pinnedDate: Date?
    let applicationName: String?
    let bundleIdentifier: String?

    init(
        id: UUID = UUID(),
        textContent: String? = nil,
        imagePath: String? = nil,
        type: ClipboardItemType,
        dateCreated: Date = Date(),
        isPinned: Bool = false,
        pinnedDate: Date? = nil,
        applicationName: String? = nil,
        bundleIdentifier: String? = nil
    ) {
        self.id = id
        self.textContent = textContent
        self.imagePath = imagePath
        self.type = type
        self.dateCreated = dateCreated
        self.isPinned = isPinned
        self.pinnedDate = pinnedDate
        self.applicationName = applicationName
        self.bundleIdentifier = bundleIdentifier
    }
}
