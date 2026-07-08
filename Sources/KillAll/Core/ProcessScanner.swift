import Foundation

/// One raw process row from `ps`, before any dev-filtering.
struct RawProcess {
    let pid: Int32
    let ppid: Int32
    let etimes: Int
    let cpu: Double
    let rssKB: Double
    let uid: UInt32
    let command: String
}

enum ProcessScannerError: LocalizedError {
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .launchFailed(let msg): return "无法读取进程列表：\(msg)"
        }
    }
}

/// Reads the full process table via `/bin/ps`. No special entitlements required.
enum ProcessScanner {
    static func scan() throws -> [RawProcess] {
        parse(try runPS())
    }

    private static func runPS() throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        // Empty `=` headers suppress the header line. `command` is last (contains spaces).
        // Note: macOS ps has `etime` ([[dd-]hh:]mm:ss), NOT Linux's `etimes` (raw seconds).
        process.arguments = ["-axww", "-o", "pid=,ppid=,etime=,pcpu=,rss=,uid=,command="]
        let out = Pipe()
        process.standardOutput = out
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            throw ProcessScannerError.launchFailed(error.localizedDescription)
        }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func parse(_ output: String) -> [RawProcess] {
        var result: [RawProcess] = []
        for rawLine in output.split(separator: "\n") {
            let parts = rawLine.split(whereSeparator: { $0 == " " || $0 == "\t" })
            // 6 fixed numeric fields + at least one command token.
            guard parts.count >= 7,
                  let pid = Int32(parts[0]),
                  let ppid = Int32(parts[1]),
                  let etimes = parseETimeSeconds(parts[2]),
                  let cpu = Double(parts[3]),
                  let rss = Double(parts[4]),
                  let uid = UInt32(parts[5])
            else { continue }
            let command = parts[6...].joined(separator: " ")
            result.append(RawProcess(pid: pid, ppid: ppid, etimes: etimes,
                                     cpu: cpu, rssKB: rss, uid: uid, command: command))
        }
        return result
    }

    /// Converts `ps` etime (`[[dd-]hh:]mm:ss`) into total seconds.
    static func parseETimeSeconds(_ field: Substring) -> Int? {
        var days = 0
        var timePart = Substring(field)
        if let dash = timePart.firstIndex(of: "-") {
            days = Int(timePart[..<dash]) ?? 0
            timePart = timePart[timePart.index(after: dash)...]
        }
        let comps = timePart.split(separator: ":").map { Int($0) ?? 0 }
        let h: Int, m: Int, s: Int
        switch comps.count {
        case 3: (h, m, s) = (comps[0], comps[1], comps[2])
        case 2: (h, m, s) = (0, comps[0], comps[1])
        case 1: (h, m, s) = (0, 0, comps[0])
        default: return nil
        }
        return ((days * 24 + h) * 60 + m) * 60 + s
    }
}
