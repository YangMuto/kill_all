import SwiftUI

@main
struct KillAllApp: App {
    @StateObject private var monitor = ProcessMonitor()

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
