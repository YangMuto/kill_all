import Foundation
import Darwin
import SwiftUI

/// Orchestrates scanning, filtering, and killing; drives the UI via `@Published`.
@MainActor
final class ProcessMonitor: ObservableObject {
    @Published private(set) var processes: [DevProcess] = []
    @Published private(set) var lastError: String?

    /// When on, also list VS Code / Cursor / Electron Node helper processes. Persisted.
    @Published var includeGUIHelpers: Bool {
        didSet {
            UserDefaults.standard.set(includeGUIHelpers, forKey: Self.guiHelpersKey)
            refresh()
        }
    }
    private static let guiHelpersKey = "includeGUIHelpers"

    /// Launch KillAll automatically at login. Reflects the real system state.
    @Published var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != oldValue else { return }
            if !LoginItem.setEnabled(launchAtLogin) {
                // Registration failed — snap back to the real status.
                launchAtLogin = LoginItem.isEnabled
            }
        }
    }
    private static let didInitLoginKey = "didInitLoginItem"

    /// Processes running at least this long are highlighted red. Change here to tune.
    let redThresholdSeconds = 3600            // 1 hour
    private let refreshInterval: TimeInterval = 3
    private let escalateAfter: TimeInterval = 2   // SIGTERM -> SIGKILL grace period

    private var timer: Timer?
    private var rawSnapshot: [RawProcess] = []
    private let ownPID = ProcessInfo.processInfo.processIdentifier
    private let currentUID = getuid()

    init() {
        includeGUIHelpers = UserDefaults.standard.bool(forKey: Self.guiHelpersKey)

        // First launch after install: opt into launch-at-login automatically.
        if !UserDefaults.standard.bool(forKey: Self.didInitLoginKey) {
            LoginItem.setEnabled(true)
            UserDefaults.standard.set(true, forKey: Self.didInitLoginKey)
        }
        launchAtLogin = LoginItem.isEnabled

        refresh()
        start()
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.refresh() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Count of processes over the red threshold (for the menu-bar icon state).
    var alertCount: Int {
        processes.filter { $0.elapsedSeconds >= redThresholdSeconds }.count
    }

    func refresh() {
        do {
            let raw = try ProcessScanner.scan()
            rawSnapshot = raw
            let matched = raw.filter {
                DevProcessFilter.isDevProcess($0, ownPID: ownPID, currentUID: currentUID,
                                              includeGUIHelpers: includeGUIHelpers)
            }
            // Resolve cwd only for the small matched set (one lsof call).
            let cwds = WorkingDirResolver.resolve(pids: matched.map { $0.pid })
            processes = matched
                .map { r in
                    DevProcess(pid: r.pid,
                               ppid: r.ppid,
                               name: DevProcessFilter.displayName(from: r.command),
                               command: r.command,
                               elapsedSeconds: r.etimes,
                               cpuPercent: r.cpu,
                               memoryMB: r.rssKB / 1024.0,
                               workingDir: cwds[r.pid],
                               isGUIHelper: DevProcessFilter.isGUIHelper(r.command))
                }
                .sorted { $0.elapsedSeconds > $1.elapsedSeconds }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func killProcess(_ proc: DevProcess) {
        killTrees(roots: [proc.pid])
    }

    func killAll() {
        killTrees(roots: processes.map { $0.pid })
    }

    private func killTrees(roots: [Int32]) {
        var targets = Set<Int32>()
        for root in roots {
            for pid in ProcessKiller.processTree(root: root, all: rawSnapshot) {
                targets.insert(pid)
            }
        }
        targets.remove(ownPID)
        let pids = Array(targets)

        ProcessKiller.sendSignal(SIGTERM, to: pids)
        refresh()

        // Escalate to SIGKILL for anything still alive after the grace period.
        DispatchQueue.main.asyncAfter(deadline: .now() + escalateAfter) { [weak self] in
            let survivors = pids.filter { ProcessKiller.isAlive($0) }
            if !survivors.isEmpty {
                ProcessKiller.sendSignal(SIGKILL, to: survivors)
            }
            self?.refresh()
        }
    }
}
