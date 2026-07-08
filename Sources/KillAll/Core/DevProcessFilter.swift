import Foundation

/// Decides which raw processes count as "development" processes worth showing.
enum DevProcessFilter {
    /// Language runtimes / interpreters recognised by their executable basename.
    static let devExecutables: Set<String> = [
        "node", "deno", "bun",
        "python", "python2", "python3", "python3.9", "python3.10",
        "python3.11", "python3.12", "python3.13",
        "ruby", "java", "go", "php", "dotnet", "perl",
        "cargo", "rustc", "gradle",
    ]

    /// Dev CLI / tool names recognised as any token's basename in the command.
    static let devCLINames: Set<String> = [
        "npm", "npx", "pnpm", "yarn",
        "vite", "webpack", "webpack-dev-server", "esbuild", "rollup",
        "parcel", "turbopack", "next", "nuxt", "nodemon", "ts-node",
        "tsx", "tsc", "gulp", "grunt", "svelte-kit",
        "jest", "vitest", "mocha", "karma", "playwright", "cypress",
        "expo", "metro", "storybook", "react-scripts", "http-server", "serve",
        "uvicorn", "gunicorn", "flask", "celery", "streamlit",
        "jupyter", "jupyter-lab", "jupyter-notebook",
        "rails", "sidekiq", "puma", "hypercorn", "daphne",
    ]

    /// Distinctive substrings that mark dev tooling inside a full command line.
    static let scriptMarkers: [String] = [
        "manage.py", "npm-cli.js", "npx-cli.js",
        "webpack", "vite", "gunicorn", "uvicorn", "nodemon",
    ]

    /// Plain shell wrappers. A `zsh -c "… npm run dev"` matches our markers because the
    /// dev command sits in its args, but it's just a launcher — the real dev process runs
    /// as a child we catch separately. Hiding the shell keeps the list clean.
    static let shellNames: Set<String> = [
        "sh", "bash", "zsh", "fish", "dash", "ksh", "tcsh", "csh",
        "-sh", "-bash", "-zsh", "login",
    ]

    /// GUI-app helper processes (VS Code, Cursor, Electron, browsers) live inside a
    /// `.app` bundle; by default they are hidden as noise, shown only opt-in.
    static func isGUIHelper(_ command: String) -> Bool {
        command.contains(".app/Contents/")
    }

    /// A GUI helper that actually hosts a Node/JS runtime — VS Code / Cursor / Electron
    /// utility "NodeService" workers and extension hosts — as opposed to GPU/renderer
    /// helpers. Only these are worth showing when the user opts into GUI helpers.
    static func isNodeHelper(_ command: String) -> Bool {
        let lower = command.lowercased()
        return lower.contains("nodeservice")
            || lower.contains("node.mojom")
            || lower.contains("--node-ipc")
            || lower.contains(".js")
    }

    /// Basename of the executable (first command token).
    static func executableName(from command: String) -> String {
        let first = command.split(whereSeparator: { $0 == " " }).first.map(String.init) ?? command
        return (first as NSString).lastPathComponent
    }

    /// A readable name for display. For GUI-app helpers the executable path contains
    /// spaces ("Visual Studio Code.app/…"), so derive the app name from the bundle;
    /// otherwise fall back to the executable basename.
    static func displayName(from command: String) -> String {
        if let range = command.range(of: ".app/") {
            let base = (String(command[..<range.lowerBound]) as NSString).lastPathComponent
            if !base.isEmpty { return base }
        }
        return executableName(from: command)
    }

    private static func tokenBasenames(_ command: String) -> [String] {
        command.split(whereSeparator: { $0 == " " }).map { token in
            (String(token) as NSString).lastPathComponent
        }
    }

    static func isDevProcess(_ raw: RawProcess,
                             ownPID: Int32,
                             currentUID: UInt32,
                             includeGUIHelpers: Bool = false) -> Bool {
        if raw.pid == ownPID { return false }
        if raw.uid != currentUID { return false }
        if isGUIHelper(raw.command) {
            // In-bundle helpers stay hidden unless opted in AND they run Node/JS.
            return includeGUIHelpers && isNodeHelper(raw.command)
        }

        let bases = tokenBasenames(raw.command)
        if let arg0 = bases.first {
            if shellNames.contains(arg0) { return false }   // launcher, not the dev process itself
            if devExecutables.contains(arg0) { return true }
        }
        if bases.contains(where: { devCLINames.contains($0) }) { return true }

        let lower = raw.command.lowercased()
        return scriptMarkers.contains { lower.contains($0) }
    }
}
