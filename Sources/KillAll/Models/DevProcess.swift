import Foundation

/// A development-related process shown in the UI.
struct DevProcess: Identifiable, Equatable {
    let pid: Int32
    let ppid: Int32
    /// Short display name, e.g. "node", "python3".
    let name: String
    /// Full command line.
    let command: String
    /// Seconds elapsed since the process started (`ps etimes`).
    let elapsedSeconds: Int
    let cpuPercent: Double
    let memoryMB: Double
    /// Current working directory (best-effort via `lsof`), nil if unknown.
    let workingDir: String?
    /// True if this is a GUI-app helper (VS Code / Cursor / Electron) shown opt-in.
    let isGUIHelper: Bool

    var id: Int32 { pid }

    /// Human-friendly elapsed time, e.g. "2h 13m", "4m 7s", "9s".
    var elapsedDescription: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }

    /// Working dir with the home prefix collapsed to `~`; nil if unknown.
    var workingDirDisplay: String? {
        guard let wd = workingDir, !wd.isEmpty else { return nil }
        let home = NSHomeDirectory()
        if wd == home { return "~" }
        if wd.hasPrefix(home + "/") { return "~" + wd.dropFirst(home.count) }
        return wd
    }
}
