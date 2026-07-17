import Foundation

/// Manages "launch at login" via a LaunchAgent plist in ~/Library/LaunchAgents.
///
/// Deliberately NOT `SMAppService`: that API keys the registration to the app's code
/// signature, and this app ships ad-hoc signed — every rebuild/upgrade produces a new
/// signature, so the old registration turns into an unmanageable orphan
/// (`status == .notFound`, `unregister()` → "Operation not permitted").
/// A LaunchAgent is keyed by path, so it survives upgrades and can always be removed.
enum LoginItem {
    static let label = "com.local.killall"

    private static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    /// True when a LaunchAgent for this app is installed.
    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        enabled ? install() : remove()
    }

    private static func install() -> Bool {
        guard let exec = Bundle.main.executablePath else { return false }
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [exec],
            "RunAtLoad": true,
            "ProcessType": "Interactive",
        ]
        do {
            try FileManager.default.createDirectory(
                at: plistURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try PropertyListSerialization.data(
                fromPropertyList: plist, format: .xml, options: 0
            )
            // Always rewrite: self-heals a stale path after the app moves or upgrades.
            // Deliberately not `launchctl bootstrap`d here: the plist has RunAtLoad, so
            // loading it now would spawn a second instance alongside the running app.
            // launchd picks it up at the next login, which is exactly the intent.
            try data.write(to: plistURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    private static func remove() -> Bool {
        bootout()
        do {
            if FileManager.default.fileExists(atPath: plistURL.path) {
                try FileManager.default.removeItem(at: plistURL)
            }
            return true
        } catch {
            return false
        }
    }

    /// Best-effort: unload if a previous login already loaded the agent.
    private static func bootout() {
        runLaunchctl(["bootout", "gui/\(getuid())/\(label)"])
    }

    private static func runLaunchctl(_ args: [String]) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        p.arguments = args
        p.standardOutput = Pipe()
        p.standardError = Pipe()
        try? p.run()
        p.waitUntilExit()
    }

    /// Maintenance helper: remove this app's login item, printing what happened.
    static func forceUnregisterWithDiagnostics() {
        print("plist: \(plistURL.path)")
        print("exists before: \(isEnabled)")
        _ = remove()
        print("exists after: \(isEnabled)")
    }
}
