import Foundation
import ServiceManagement

/// Manages "launch at login" via the modern `SMAppService` (macOS 13+).
/// No helper target or signing certificate required.
enum LoginItem {
    /// Whether the app is currently registered to launch at login.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Register / unregister as a login item. Returns false on failure
    /// (e.g. the system needs user approval in System Settings > 登录项).
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            let service = SMAppService.mainApp
            if enabled {
                if service.status != .enabled { try service.register() }
            } else {
                if service.status == .enabled { try service.unregister() }
            }
            return true
        } catch {
            return false
        }
    }
}
