import Foundation

/// Tiny IPC layer for the containing app <-> keyboard extension.
///
/// Uses two mechanisms:
/// - App Group UserDefaults for durable command/result state.
/// - Darwin notifications for low-latency cross-process wake-up when the host app is alive.
///
/// Note: App Group sharing requires both app and extension to be signed with the
/// matching application-group entitlement (`group.com.mawa.flow`).
enum MawaIPC {
    static let appGroupID = "group.com.mawa.flow"

    enum NotificationName {
        static let startRecording = "com.mawa.flow.ipc.startRecording"
        static let stopRecording = "com.mawa.flow.ipc.stopRecording"
        static let resultReady = "com.mawa.flow.ipc.resultReady"
    }

    enum Key {
        static let command = "mawa.ipc.command"
        static let requestID = "mawa.ipc.requestID"
        static let mode = "mawa.ipc.mode"
        static let state = "mawa.ipc.state"
        static let resultRequestID = "mawa.ipc.resultRequestID"
        static let resultTranscript = "mawa.ipc.resultTranscript"
        static let resultError = "mawa.ipc.resultError"
        static let updatedAt = "mawa.ipc.updatedAt"
    }

    enum Command {
        static let start = "start"
        static let stop = "stop"
    }

    enum State {
        static let idle = "idle"
        static let recording = "recording"
        static let processing = "processing"
        static let ready = "ready"
        static let failed = "failed"
    }

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func post(_ name: String) {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(name as CFString),
            nil,
            nil,
            true
        )
    }

    static func writeCommand(_ command: String, requestID: String, mode: String) -> Bool {
        guard let defaults = sharedDefaults else { return false }
        defaults.set(command, forKey: Key.command)
        defaults.set(requestID, forKey: Key.requestID)
        defaults.set(mode, forKey: Key.mode)
        defaults.set(Date().timeIntervalSince1970, forKey: Key.updatedAt)
        defaults.set("", forKey: Key.resultTranscript)
        defaults.set("", forKey: Key.resultError)
        defaults.synchronize()
        return true
    }

    static func writeState(_ state: String, requestID: String? = nil, transcript: String? = nil, error: String? = nil) {
        guard let defaults = sharedDefaults else { return }
        defaults.set(state, forKey: Key.state)
        if let requestID { defaults.set(requestID, forKey: Key.resultRequestID) }
        if let transcript { defaults.set(transcript, forKey: Key.resultTranscript) }
        if let error { defaults.set(error, forKey: Key.resultError) }
        defaults.set(Date().timeIntervalSince1970, forKey: Key.updatedAt)
        defaults.synchronize()
    }
}

final class MawaDarwinNotificationObserver {
    private let name: String
    private let callback: () -> Void

    init(name: String, callback: @escaping () -> Void) {
        self.name = name
        self.callback = callback
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer else { return }
                let instance = Unmanaged<MawaDarwinNotificationObserver>.fromOpaque(observer).takeUnretainedValue()
                instance.callback()
            },
            name as CFString,
            nil,
            .deliverImmediately
        )
    }

    deinit {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(name as CFString),
            nil
        )
    }
}
