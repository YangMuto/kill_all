import Foundation

/// Resolves each process's current working directory via a single `lsof` call.
/// Best-effort: on any failure the pid is simply absent from the result.
enum WorkingDirResolver {
    static func resolve(pids: [Int32]) -> [Int32: String] {
        guard !pids.isEmpty else { return [:] }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        // -a AND the selections; -d cwd only the cwd descriptor; -Fpn field output.
        process.arguments = [
            "-a", "-d", "cwd", "-Fpn",
            "-p", pids.map(String.init).joined(separator: ","),
        ]
        let out = Pipe()
        process.standardOutput = out
        process.standardError = Pipe()
        do { try process.run() } catch { return [:] }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard let text = String(data: data, encoding: .utf8) else { return [:] }

        // Field output: `p<pid>` starts a set, `n<path>` is the cwd (we ignore `f`).
        var result: [Int32: String] = [:]
        var currentPID: Int32?
        for line in text.split(separator: "\n") {
            guard let tag = line.first else { continue }
            let value = line.dropFirst()
            switch tag {
            case "p": currentPID = Int32(value)
            case "n": if let pid = currentPID { result[pid] = String(value) }
            default: break
            }
        }
        return result
    }
}
