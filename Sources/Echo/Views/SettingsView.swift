import AppKit
import Carbon
import SwiftUI

struct SettingsView: View {
    @AppStorage("retentionDays") private var retentionDays: Int = 30
    @EnvironmentObject var historyManager: HistoryManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section(header: Text("General")) {
                ShortcutRecorderView()
            }

            Section(header: Text("History")) {
                Picker("Keep History For", selection: $retentionDays) {
                    Text("1 Day").tag(1)
                    Text("7 Days").tag(7)
                    Text("30 Days").tag(30)
                    Text("3 Months").tag(90)
                    Text("1 Year").tag(365)
                    Text("Forever").tag(Int.max)
                }
                .onChange(of: retentionDays) {
                    historyManager.retentionDays = retentionDays
                }
            }

            Section(header: Text("Permissions")) {
                HStack {
                    Text("Accessibility Access")
                    Spacer()
                    if PasteManager.shared.checkAccessibilityPermissions() {
                        Text("Granted")
                            .foregroundColor(.green)
                    } else {
                        Text("Not Granted")
                            .foregroundColor(.red)
                        Button("Open Settings") {
                            if let url = URL(
                                string:
                                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                            ) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
                    }
                }
                Text("Required for pasting directly to other apps.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Actions")) {
                Button(role: .destructive) {
                    historyManager.clearUnpinnedHistory()
                } label: {
                    Label("Clear Unpinned History", systemImage: "trash")
                }
            }

            Section(header: Text("About")) {
                Text("Echo v1.0")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
        .toolbar {
            Button("Done") {
                dismiss()
            }
        }
    }
}

class ShortcutRecorderViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var keyCode: UInt32
    @Published var modifiers: UInt32

    private var monitor: Any?

    init() {
        if UserDefaults.standard.object(forKey: "hotKeyKeyCode") != nil {
            self.keyCode = UInt32(UserDefaults.standard.integer(forKey: "hotKeyKeyCode"))
            self.modifiers = UInt32(UserDefaults.standard.integer(forKey: "hotKeyModifiers"))
        } else {
            self.keyCode = UInt32(kVK_ANSI_C)
            self.modifiers = UInt32(cmdKey | shiftKey)
        }
    }

    deinit {
        stopRecording()
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        stopRecording()
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            if event.keyCode == kVK_Escape {
                self.stopRecording()
                return nil
            }

            var mods: UInt32 = 0
            if event.modifierFlags.contains(.command) { mods |= UInt32(cmdKey) }
            if event.modifierFlags.contains(.shift) { mods |= UInt32(shiftKey) }
            if event.modifierFlags.contains(.option) { mods |= UInt32(optionKey) }
            if event.modifierFlags.contains(.control) { mods |= UInt32(controlKey) }

            self.keyCode = UInt32(event.keyCode)
            self.modifiers = mods

            HotKeyManager.shared.setShortcut(keyCode: self.keyCode, modifiers: self.modifiers)

            self.stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        isRecording = false
    }

    var shortcutString: String {
        var str = ""
        if modifiers & UInt32(controlKey) != 0 { str += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { str += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { str += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { str += "⌘" }

        if let special = ShortcutHelper.specialKeys[Int(keyCode)] {
            str += special
        } else {
            str += ShortcutHelper.keyString(for: keyCode)
        }
        return str
    }
}

struct ShortcutHelper {
    static func keyString(for code: UInt32) -> String {
        let c = Int(code)
        if c == kVK_ANSI_A { return "A" }
        if c == kVK_ANSI_B { return "B" }
        if c == kVK_ANSI_C { return "C" }
        if c == kVK_ANSI_D { return "D" }
        if c == kVK_ANSI_E { return "E" }
        if c == kVK_ANSI_F { return "F" }
        if c == kVK_ANSI_G { return "G" }
        if c == kVK_ANSI_H { return "H" }
        if c == kVK_ANSI_I { return "I" }
        if c == kVK_ANSI_J { return "J" }
        if c == kVK_ANSI_K { return "K" }
        if c == kVK_ANSI_L { return "L" }
        if c == kVK_ANSI_M { return "M" }
        if c == kVK_ANSI_N { return "N" }
        if c == kVK_ANSI_O { return "O" }
        if c == kVK_ANSI_P { return "P" }
        if c == kVK_ANSI_Q { return "Q" }
        if c == kVK_ANSI_R { return "R" }
        if c == kVK_ANSI_S { return "S" }
        if c == kVK_ANSI_T { return "T" }
        if c == kVK_ANSI_U { return "U" }
        if c == kVK_ANSI_V { return "V" }
        if c == kVK_ANSI_W { return "W" }
        if c == kVK_ANSI_X { return "X" }
        if c == kVK_ANSI_Y { return "Y" }
        if c == kVK_ANSI_Z { return "Z" }
        if c == kVK_ANSI_0 { return "0" }
        if c == kVK_ANSI_1 { return "1" }
        if c == kVK_ANSI_2 { return "2" }
        if c == kVK_ANSI_3 { return "3" }
        if c == kVK_ANSI_4 { return "4" }
        if c == kVK_ANSI_5 { return "5" }
        if c == kVK_ANSI_6 { return "6" }
        if c == kVK_ANSI_7 { return "7" }
        if c == kVK_ANSI_8 { return "8" }
        if c == kVK_ANSI_9 { return "9" }
        return "?"
    }

    static var specialKeys: [Int: String] {
        [
            kVK_Space: "Space",
            kVK_Return: "Return",
            kVK_Tab: "Tab",
            kVK_Delete: "Delete",
            kVK_ForwardDelete: "Del",
            kVK_Escape: "Esc",
            kVK_Command: "Cmd",
            kVK_Shift: "Shift",
            kVK_CapsLock: "Caps",
            kVK_Option: "Option",
            kVK_Control: "Ctrl",
            kVK_Function: "Fn",
            kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
            kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8",
            kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
        ]
    }
}

struct ShortcutRecorderView: View {
    @StateObject private var viewModel = ShortcutRecorderViewModel()

    var body: some View {
        HStack {
            Text("Global Shortcut")
            Spacer()
            Button(action: {
                viewModel.toggleRecording()
            }) {
                Text(viewModel.isRecording ? "Press keys..." : viewModel.shortcutString)
                    .frame(minWidth: 100)
            }
        }
    }
}
