import Carbon
import Cocoa

// Global handler function for C API callback
private func hotKeyHandler(
    nextHandler: EventHandlerCallRef?, event: EventRef?, userData: UnsafeMutableRawPointer?
) -> OSStatus {
    HotKeyManager.shared.handleHotKey()
    return noErr
}

class HotKeyManager {
    static let shared = HotKeyManager()

    var onTrigger: (() -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    var keyCode: UInt32 {
        get {
            UserDefaults.standard.object(forKey: "hotKeyKeyCode") != nil
                ? UInt32(UserDefaults.standard.integer(forKey: "hotKeyKeyCode"))
                : UInt32(kVK_ANSI_C)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hotKeyKeyCode")
            updateHotKey()
        }
    }

    var modifiers: UInt32 {
        get {
            UserDefaults.standard.object(forKey: "hotKeyModifiers") != nil
                ? UInt32(UserDefaults.standard.integer(forKey: "hotKeyModifiers"))
                : UInt32(cmdKey | shiftKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hotKeyModifiers")
            updateHotKey()
        }
    }

    private init() {}

    func register(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
        installEventHandler()
        updateHotKey()
    }

    func setShortcut(keyCode: UInt32, modifiers: UInt32) {
        UserDefaults.standard.set(keyCode, forKey: "hotKeyKeyCode")
        UserDefaults.standard.set(modifiers, forKey: "hotKeyModifiers")
        updateHotKey()
    }

    private func installEventHandler() {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyHandler,
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )
    }

    private func updateHotKey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(1_196_381_003)  // 'ghk1'
        hotKeyID.id = 1

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            print("Failed to register hotkey: \(status)")
        }
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handlerRef = eventHandlerRef {
            RemoveEventHandler(handlerRef)
            eventHandlerRef = nil
        }
    }

    func handleHotKey() {
        DispatchQueue.main.async {
            self.onTrigger?()
        }
    }
}
