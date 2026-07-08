import SwiftUI
import AppKit

/// The popover panel shown from the menu-bar icon.
struct MenuPanelView: View {
    @EnvironmentObject var monitor: ProcessMonitor
    @State private var confirmingKillAll = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 400)
        .onDisappear { confirmingKillAll = false }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dev Processes").font(.headline)
                Text("\(monitor.processes.count) 个运行中 · \(monitor.alertCount) 个超 1 小时")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            killAllControl
        }
        .padding(12)
    }

    /// Inline two-step confirm. A system `confirmationDialog` cannot be used here:
    /// presenting it makes the menu-bar window resign key and hide, dropping the action.
    @ViewBuilder
    private var killAllControl: some View {
        if confirmingKillAll {
            HStack(spacing: 6) {
                Button(role: .destructive) {
                    monitor.killAll()
                    confirmingKillAll = false
                } label: {
                    Text("确认杀 \(monitor.processes.count) 个")
                }
                Button("取消") { confirmingKillAll = false }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
            .font(.callout)
        } else {
            Button(role: .destructive) {
                confirmingKillAll = true
            } label: {
                Label("Kill All", systemImage: "xmark.octagon.fill")
            }
            .disabled(monitor.processes.isEmpty)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let err = monitor.lastError {
            errorView(err)
        } else if monitor.processes.isEmpty {
            emptyView
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(monitor.processes) { proc in
                        ProcessRowView(
                            proc: proc,
                            isOver: proc.elapsedSeconds >= monitor.redThresholdSeconds
                        ) {
                            monitor.killProcess(proc)
                        }
                        Divider()
                    }
                }
            }
            .frame(maxHeight: 420)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle").font(.largeTitle).foregroundStyle(.green)
            Text("没有正在运行的开发进程").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundStyle(.orange)
            Text(msg).font(.caption).multilineTextAlignment(.center).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var footer: some View {
        HStack {
            Toggle("显示 GUI 应用 Node 助手", isOn: $monitor.includeGUIHelpers)
                .toggleStyle(.checkbox)
                .help("同时显示 VS Code / Cursor / Electron 等 GUI 应用派生的 Node 助手进程")

            Spacer()

            Button { monitor.refresh() } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain).foregroundStyle(.secondary)
            .help("刷新")

            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.plain).foregroundStyle(.secondary)
            .help("退出 KillAll")
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
