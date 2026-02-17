import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var historyManager: HistoryManager
    @State private var searchText = ""
    @State private var selectedItemId: UUID?
    @State private var showSettings = false
    @State private var hoveredItemId: UUID?
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    var filteredItems: [ClipboardItem] {
        let items: [ClipboardItem]
        if searchText.isEmpty {
            items = historyManager.items
        } else {
            items = historyManager.items.filter { item in
                item.textContent?.localizedCaseInsensitiveContains(searchText) == true
                    || item.applicationName?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Sort: Pinned first, then by date (descending)
        return items.sorted { (item1, item2) -> Bool in
            if item1.isPinned && !item2.isPinned {
                return true
            } else if !item1.isPinned && item2.isPinned {
                return false
            } else {
                return item1.dateCreated > item2.dateCreated
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Pane (Search & List)
            VStack(spacing: 0) {
                searchHeader
                Divider().background(Color.white.opacity(0.06)).frame(height: 0.5)
                listView
            }
            .frame(width: 280)
            .background(Material.ultraThin)

            // MARK: - Accent edge divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.3),
                            Color.accentColor.opacity(0.08),
                            Color.accentColor.opacity(0.3),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1)

            // MARK: - Right Pane (Preview)
            VStack(spacing: 0) {
                if let selectedId = selectedItemId,
                    let item = historyManager.items.first(where: { $0.id == selectedId })
                {
                    PreviewPane(item: item, historyManager: historyManager)
                } else if !searchText.isEmpty && filteredItems.isEmpty {
                    EmptySearchState(searchText: searchText)
                } else {
                    EmptyPreviewState()
                }

                Divider().background(Color.white.opacity(0.06)).frame(height: 0.5)

                footerBar
            }
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Color(nsColor: .windowBackgroundColor)
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.03),
                            Color.clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
        }
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .frame(width: 800, height: 500)
        .onAppear {
            selectedItemId = filteredItems.first?.id
            isSearchFocused = true
        }
        .onChange(of: filteredItems) {
            if selectedItemId == nil || !filteredItems.contains(where: { $0.id == selectedItemId })
            {
                selectedItemId = filteredItems.first?.id
            }
        }
        // Keyboard Handling
        .background(Color.clear.focusable())
        .onKeyPress(.downArrow) {
            moveSelection(direction: 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            moveSelection(direction: -1)
            return .handled
        }
        .onKeyPress(.return) {
            if let selectedId = selectedItemId,
                let item = filteredItems.first(where: { $0.id == selectedId })
            {
                pasteItem(item)
                return .handled
            }
            return .ignored
        }
        // Seamless Typing
        .onKeyPress { press in
            guard !isSearchFocused, press.modifiers.isEmpty else { return .ignored }
            let chars = press.characters
            if !chars.isEmpty, let first = chars.first,
                first.isLetter || first.isNumber || first.isPunctuation || first.isSymbol
                    || first == " "
            {
                searchText.append(chars)
                isSearchFocused = true
                return .handled
            }
            return .ignored
        }
        // Shortcuts
        .background(hiddenButtons)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPreferences)) { _ in
            showSettings = true
        }
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in
            searchText = ""
            isSearchFocused = true

            // Select the most recently created item (last copy)
            let mostRecentItem = historyManager.items.max(by: { $0.dateCreated < $1.dateCreated })
            selectedItemId = mostRecentItem?.id
        }
    }

    // MARK: - Subviews

    private var searchHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.accentColor.opacity(0.8))

            TextField("Type to search history...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .font(.system(size: 14))
                .onKeyPress(.downArrow) {
                    moveSelection(direction: 1)
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    moveSelection(direction: -1)
                    return .handled
                }
                .onSubmit {
                    if let selectedId = selectedItemId,
                        let item = filteredItems.first(where: { $0.id == selectedId })
                    {
                        pasteItem(item)
                    } else if let first = filteredItems.first {
                        pasteItem(first)
                    }
                }

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.15))
    }

    private var listView: some View {
        ScrollViewReader { proxy in
            List(selection: $selectedItemId) {
                let pinned = filteredItems.filter { $0.isPinned }
                let recent = filteredItems.filter { !$0.isPinned }

                if !pinned.isEmpty {
                    Section(
                        header: HStack(spacing: 4) {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.orange.opacity(0.7))
                            Text("Pinned")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .textCase(nil)
                    ) {
                        ForEach(pinned) { item in
                            rowView(for: item)
                        }
                    }
                }

                if !recent.isEmpty {
                    Section(
                        header: HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("Recent")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .textCase(nil)
                    ) {
                        ForEach(recent) { item in
                            rowView(for: item)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onChange(of: selectedItemId) {
                if let id = selectedItemId {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rowView(for item: ClipboardItem) -> some View {
        ModernListItem(
            item: item,
            isSelected: selectedItemId == item.id,
            isHovered: hoveredItemId == item.id,
            historyManager: historyManager
        )
        .tag(item.id)
        .listRowInsets(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
        .listRowSeparator(.hidden)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    selectedItemId == item.id
                        ? Color.accentColor
                        : (hoveredItemId == item.id
                            ? Color.primary.opacity(0.05) : Color.clear)
                )
                .animation(.easeInOut(duration: 0.12), value: hoveredItemId)
                .animation(.easeInOut(duration: 0.15), value: selectedItemId)
        )
        .onHover { isHovered in
            hoveredItemId = isHovered ? item.id : nil
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedItemId = item.id
            }
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                pasteItem(item)
            }
        )
        .contextMenu {
            contextMenuButtons(for: item)
        }
    }

    private var footerBar: some View {
        HStack(spacing: 16) {
            shortcutLabel("⌘.", text: "Settings")
                .onTapGesture { showSettings = true }
                .contentShape(Rectangle())

            Spacer()

            // Item count
            Text("\(filteredItems.count) item\(filteredItems.count == 1 ? "" : "s")")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.4))

            shortcutLabel("↩", text: "Paste")
            shortcutLabel("↑↓", text: "Navigate")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.25))
    }

    @ViewBuilder
    private func shortcutLabel(_ key: String, text: String) -> some View {
        HStack(spacing: 5) {
            Text(key)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary.opacity(0.9))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                        )
                )
            Text(text)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }

    private var hiddenButtons: some View {
        Group {
            Button("Settings") { showSettings.toggle() }
                .keyboardShortcut(".", modifiers: .command)
        }
        .hidden()
    }

    // MARK: - Logic & Actions

    private func moveSelection(direction: Int) {
        guard !filteredItems.isEmpty else { return }
        let currentIndex = filteredItems.firstIndex(where: { $0.id == selectedItemId }) ?? -1
        var newIndex = currentIndex + direction
        if newIndex < 0 {
            newIndex = 0
        } else if newIndex >= filteredItems.count {
            newIndex = filteredItems.count - 1
        }

        if newIndex >= 0 && newIndex < filteredItems.count {
            withAnimation(.easeInOut(duration: 0.12)) {
                selectedItemId = filteredItems[newIndex].id
            }
        }
    }

    private func pasteItem(_ item: ClipboardItem) {
        copyToClipboard(item)
        PasteManager.shared.paste()
    }

    private func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let text = item.textContent {
            pasteboard.setString(text, forType: .string)
        } else if let imagePath = item.imagePath,
            let url = historyManager.getImageUrl(for: imagePath),
            let image = NSImage(contentsOf: url)
        {
            pasteboard.writeObjects([image])
        }
        NSSound(named: "Pop")?.play()
    }

    @ViewBuilder
    private func contextMenuButtons(for item: ClipboardItem) -> some View {
        Button {
            pasteItem(item)
        } label: {
            Label("Paste", systemImage: "arrow.turn.up.left")
        }
        Button {
            copyToClipboard(item)
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
        Button {
            historyManager.togglePin(for: item.id)
        } label: {
            Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
        }
        Button(role: .destructive) {
            historyManager.deleteItem(id: item.id)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Sub Views

struct ModernListItem: View {
    let item: ClipboardItem
    let isSelected: Bool
    let isHovered: Bool
    let historyManager: HistoryManager

    var body: some View {
        HStack(spacing: 10) {
            // Icon / Thumbnail
            if item.type == .image, let imagePath = item.imagePath,
                let url = historyManager.getImageUrl(for: imagePath),
                let nsImage = NSImage(contentsOf: url)
            {
                // Image thumbnail
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.08),
                                lineWidth: 0.5)
                    )
            } else {
                // Text icon
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(
                                isSelected
                                    ? Color.white.opacity(0.15) : Color.primary.opacity(0.06))
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(titleText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(item.applicationName ?? "Unknown")
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)

                    Text("·")
                        .foregroundColor(
                            isSelected ? .white.opacity(0.5) : .secondary.opacity(0.6))

                    Text(timeAgo(item.dateCreated))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)

                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .orange)
                    }
                }
                .font(.system(size: 11))
            }
            Spacer()
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }

    private var titleText: String {
        if let text = item.textContent {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return "Image Captured"
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct PreviewPane: View {
    let item: ClipboardItem
    let historyManager: HistoryManager

    private var isCodeLike: Bool {
        guard let text = item.textContent else { return false }
        let codeIndicators = [
            "{", "}", "()", "=>", "->", "func ", "def ", "class ", "import ",
            "const ", "let ", "var ", "return ", "if (", "for (", "<div", "</",
            "SELECT ", "FROM ", "INSERT ", "CREATE ",
        ]
        let matchCount = codeIndicators.filter { text.contains($0) }.count
        return matchCount >= 2
    }

    private var textStats: (chars: Int, words: Int, lines: Int)? {
        guard let text = item.textContent else { return nil }
        let chars = text.count
        let words = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        let lines = text.components(separatedBy: .newlines).count
        return (chars, words, lines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 14) {
                // Icon with accent background
                Group {
                    if item.type == .text {
                        Image(
                            systemName: isCodeLike
                                ? "chevron.left.forwardslash.chevron.right" : "doc.text.fill")
                    } else {
                        Image(systemName: "photo.fill")
                    }
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: item.type == .text
                                    ? (isCodeLike
                                        ? [Color.green.opacity(0.8), Color.green.opacity(0.5)]
                                        : [Color.blue.opacity(0.8), Color.blue.opacity(0.5)])
                                    : [Color.purple.opacity(0.8), Color.purple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.applicationName ?? "Unknown Application")
                        .font(.system(size: 16, weight: .semibold))
                    HStack(spacing: 6) {
                        Text(item.dateCreated.formatted(date: .long, time: .shortened))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        if let stats = textStats {
                            Text("·")
                                .foregroundColor(.secondary.opacity(0.4))
                            Text("\(stats.chars) chars · \(stats.words) words")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider().background(Color.white.opacity(0.06)).frame(height: 0.5)

            // Content
            ScrollView {
                VStack(alignment: .leading) {
                    if let text = item.textContent {
                        if isCodeLike {
                            // Code block styling
                            Text(text)
                                .font(.system(size: 12.5, design: .monospaced))
                                .foregroundColor(.primary.opacity(0.9))
                                .textSelection(.enabled)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.25))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                                        )
                                )
                                .padding(14)
                        } else {
                            Text(text)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.primary.opacity(0.85))
                                .textSelection(.enabled)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else if let imagePath = item.imagePath,
                        let url = historyManager.getImageUrl(for: imagePath),
                        let nsImage = NSImage(contentsOf: url)
                    {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
                            .padding(16)
                    }
                }
            }
        }
    }
}

struct EmptyPreviewState: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.secondary.opacity(0.3), .secondary.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text("No Item Selected")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Select a clipboard entry to preview")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptySearchState: View {
    let searchText: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.secondary.opacity(0.3), .secondary.opacity(0.12)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text("No Results")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No items match \"\(searchText)\"")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.3))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
