import SwiftUI

@main
struct KillAllApp: App {
    @StateObject private var monitor = ProcessMonitor()

    init() {
        // Maintenance escape hatch: lets a copy at any path remove its own login item
        // (e.g. a stale dev build) without launching the UI.
        //   KillAll.app/Contents/MacOS/KillAll --unregister-login-item
        if CommandLine.arguments.contains("--unregister-login-item") {
            LoginItem.forceUnregisterWithDiagnostics()
            exit(0)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuPanelView()
                .environmentObject(monitor)
        } label: {
            // Icon reflects alert state: warning triangle when something is over 1h.
            Image(systemName: monitor.alertCount > 0
                  ? "exclamationmark.triangle.fill"
                  : "bolt.horizontal.circle")
        }
        .menuBarExtraStyle(.window)
    }
}
