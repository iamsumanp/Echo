import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var historyManager: HistoryManager
    @State private var searchText = ""
    @State private var selectedItemId: UUID?
    @State private var showSettings = false
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
                Divider().opacity(0.3)
                listView
            }
            .frame(width: 280)
            .background(Material.ultraThin)

            // MARK: - Right Pane (Preview)
            VStack(spacing: 0) {
                if let selectedId = selectedItemId,
                    let item = historyManager.items.first(where: { $0.id == selectedId })
                {
                    PreviewPane(item: item, historyManager: historyManager)
                } else {
                    EmptyPreviewState()
                }

                Divider().opacity(0.3)

                footerBar
            }
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
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
    }

    // MARK: - Subviews

    private var searchHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Type to search history...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .font(.body)
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
        }
        .padding(12)
        .background(Color.black.opacity(0.1))  // Darker input background
    }

    private var listView: some View {
        ScrollViewReader { proxy in
            List(selection: $selectedItemId) {
                let pinned = filteredItems.filter { $0.isPinned }
                let recent = filteredItems.filter { !$0.isPinned }

                if !pinned.isEmpty {
                    Section(
                        header: Text("Pinned").font(.caption).fontWeight(.semibold).foregroundColor(
                            .secondary)
                    ) {
                        ForEach(pinned) { item in
                            rowView(for: item)
                        }
                    }
                }

                if !recent.isEmpty {
                    Section(
                        header: Text("Today").font(.caption).fontWeight(.semibold).foregroundColor(
                            .secondary)
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
                    withAnimation {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rowView(for item: ClipboardItem) -> some View {
        ModernListItem(item: item, isSelected: selectedItemId == item.id)
            .tag(item.id)
            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .listRowSeparator(.hidden)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedItemId == item.id ? Color.accentColor : Color.clear)
            )
            .onTapGesture {
                selectedItemId = item.id
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
            Spacer()
            shortcutLabel("↩", text: "Paste")
            shortcutLabel("↑↓", text: "Navigate")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.2))  // Dark footer
    }

    @ViewBuilder
    private func shortcutLabel(_ key: String, text: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var hiddenButtons: some View {
        Group {
            Button("Settings") { showSettings.toggle() }
                .keyboardShortcut(",", modifiers: .command)
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
            selectedItemId = filteredItems[newIndex].id
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
        NSSound(named: "Tink")?.play()
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

    var body: some View {
        HStack(spacing: 12) {
            // Static Icon
            Group {
                if item.type == .text {
                    Image(systemName: "doc.text")
                } else {
                    Image(systemName: "photo")
                }
            }
            .font(.system(size: 20))
            .foregroundColor(.secondary)
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if isSelected {
                        Text(item.applicationName ?? "Unknown")
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text(item.applicationName ?? "Unknown")
                            .foregroundColor(.secondary)
                    }

                    if isSelected {
                        Text("•")
                            .foregroundColor(.white.opacity(0.6))
                        Text(timeAgo(item.dateCreated))
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(timeAgo(item.dateCreated))
                            .foregroundColor(.secondary)
                    }

                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(isSelected ? .white : .orange)
                    }
                }
                .font(.caption)
            }
            Spacer()
        }
        .padding(.vertical, 6)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Group {
                        if item.type == .text {
                            Image(systemName: "doc.text")
                        } else {
                            Image(systemName: "photo")
                        }
                    }
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                    .frame(width: 48, height: 48)

                    VStack(alignment: .leading) {
                        Text(item.applicationName ?? "Unknown Application")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(item.dateCreated.formatted(date: .long, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading) {
                    if let text = item.textContent {
                        Text(text)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if let imagePath = item.imagePath,
                        let url = historyManager.getImageUrl(for: imagePath),
                        let nsImage = NSImage(contentsOf: url)
                    {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .padding()
                    }
                }
            }
        }
    }
}

struct EmptyPreviewState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.3))
            Text("No Item Selected")
                .font(.title2)
                .foregroundColor(.secondary)
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
