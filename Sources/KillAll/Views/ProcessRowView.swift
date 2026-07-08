import SwiftUI

/// One row: name + PID, command, elapsed time, CPU/mem, and a kill button.
struct ProcessRowView: View {
    let proc: DevProcess
    let isOver: Bool
    let onKill: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(proc.name)
                        .font(.system(.body, design: .monospaced)).bold()
                        .foregroundStyle(isOver ? Color.red : Color.primary)
                    Text("PID \(proc.pid)")
                        .font(.caption2).foregroundStyle(.secondary)
                    if proc.isGUIHelper { guiBadge }
                }
                if let dir = proc.workingDirDisplay {
                    HStack(spacing: 3) {
                        Image(systemName: "folder")
                        Text(dir).lineLimit(1).truncationMode(.middle)
                    }
                    .font(.caption2).foregroundStyle(.secondary)
                    .help(proc.workingDir ?? "")
                }
                Text(proc.command)
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
                    .lineLimit(1).truncationMode(.middle)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(proc.elapsedDescription)
                    .font(.caption).bold()
                    .foregroundStyle(isOver ? Color.red : Color.secondary)
                Text(String(format: "%.0f%% · %.0fMB", proc.cpuPercent, proc.memoryMB))
                    .font(.caption2).foregroundStyle(.secondary)
            }

            Button(action: onKill) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .help("Kill \(proc.name) (PID \(proc.pid)) 及其所有子进程")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }

    private var guiBadge: some View {
        Text("app")
            .font(.system(size: 9, weight: .semibold))
            .padding(.horizontal, 4).padding(.vertical, 1)
            .background(Color.secondary.opacity(0.20))
            .clipShape(Capsule())
            .foregroundStyle(.secondary)
    }

    private var rowBackground: Color {
        if isOver { return Color.red.opacity(0.10) }
        return hovering ? Color.secondary.opacity(0.08) : Color.clear
    }
}
