import Foundation
import Darwin

/// Computes process trees and delivers signals. Killing the whole subtree is what
/// actually frees resources: a stray `npm run dev` usually spawns child workers that
/// would be orphaned if only the parent were killed.
enum ProcessKiller {
    /// The root pid plus every descendant, derived from the ppid map.
    static func processTree(root: Int32, all: [RawProcess]) -> [Int32] {
        var childrenByParent: [Int32: [Int32]] = [:]
        for p in all {
            childrenByParent[p.ppid, default: []].append(p.pid)
        }
        var result: [Int32] = []
        var stack: [Int32] = [root]
        while let pid = stack.popLast() {
            result.append(pid)
            if let kids = childrenByParent[pid] {
                stack.append(contentsOf: kids)
            }
        }
        return result
    }

    /// Sends `signal` to each pid. Refuses pid <= 1 (0 broadcasts to a whole process
    /// group; 1 is launchd/init). Returns how many signals were delivered.
    @discardableResult
    static func sendSignal(_ signal: Int32, to pids: [Int32]) -> Int {
        var delivered = 0
        for pid in pids where pid > 1 {
            if kill(pid, signal) == 0 { delivered += 1 }
        }
        return delivered
    }

    /// True if the process still exists (signal 0 probes without delivering).
    static func isAlive(_ pid: Int32) -> Bool {
        pid > 1 && kill(pid, 0) == 0
    }
}
