import SwiftUI
import ServiceManagement

@main
struct BlackoutNotiBlockerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var dndTimer: Timer?
    var originalAlertVolume: Int = 100
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Store original alert volume to restore on quit
        captureOriginalAlertVolume()
        
        // Setup Menu Bar Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bell.slash.fill", accessibilityDescription: "BlackoutNotiBlocker")
        }
        
        setupMenu()
        setupLoginItem()
        startBlackoutEnforcement()
    }
    
    func setupMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Status: Total Blackout Active", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit BlackoutNotiBlocker (Resume Everything)", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func quit() {
        // Restore system to normal state
        resumeSystemProcesses()
        restoreAlertVolume()
        resetPreferences()
        
        NSApplication.shared.terminate(self)
    }
    
    func setupLoginItem() {
        do {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
                print("Registered to launch on login")
            }
        } catch {
            print("Failed to register SMAppService: \(error)")
        }
    }
    
    func startBlackoutEnforcement() {
        // 6-Pronged Enforcement
        enforceBlackout()
        
        // Setup a timer to continually enforce every 5 seconds
        dndTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.enforceBlackout()
        }
    }
    
    func enforceBlackout() {
        // 1. Modern DND Prefs
        let ncui = "com.apple.notificationcenterui" as CFString
        CFPreferencesSetValue("doNotDisturb" as CFString, true as CFPropertyList, ncui, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        
        // 2. Legacy DND Prefs
        let ncprefs = "com.apple.ncprefs" as CFString
        CFPreferencesSetValue("dnd_enabled" as CFString, true as CFPropertyList, ncprefs, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        
        // 3. Control Center Focus State
        let cc = "com.apple.controlcenter" as CFString
        CFPreferencesSetValue("NSStatusItem Visible FocusModes" as CFString, true as CFPropertyList, cc, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        
        CFPreferencesSynchronize(ncui, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        CFPreferencesSynchronize(ncprefs, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        CFPreferencesSynchronize(cc, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        
        DistributedNotificationCenter.default().postNotificationName(NSNotification.Name("com.apple.notificationcenterui.dndprefs_changed"), object: nil, userInfo: nil, deliverImmediately: true)
        
        // 4. Suspend NotificationCenter (UI)
        runKillall(args: ["-STOP", "NotificationCenter"])
        
        // 5. Suspend usernoted (The Daemon/Brain)
        runKillall(args: ["-STOP", "usernoted"])
        
        // 6. Mute System Alert Volume
        setAlertVolume(0)
    }
    
    func resumeSystemProcesses() {
        runKillall(args: ["-CONT", "NotificationCenter"])
        runKillall(args: ["-CONT", "usernoted"])
    }
    
    func resetPreferences() {
        let ncui = "com.apple.notificationcenterui" as CFString
        CFPreferencesSetValue("doNotDisturb" as CFString, false as CFPropertyList, ncui, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        CFPreferencesSynchronize(ncui, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        
        let ncprefs = "com.apple.ncprefs" as CFString
        CFPreferencesSetValue("dnd_enabled" as CFString, false as CFPropertyList, ncprefs, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        CFPreferencesSynchronize(ncprefs, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        
        DistributedNotificationCenter.default().postNotificationName(NSNotification.Name("com.apple.notificationcenterui.dndprefs_changed"), object: nil, userInfo: nil, deliverImmediately: true)
    }
    
    // MARK: - Helpers
    
    func runKillall(args: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = args
        try? process.run()
    }
    
    func captureOriginalAlertVolume() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "get alert volume of (get volume settings)"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           let vol = Int(output) {
            originalAlertVolume = vol
        }
    }
    
    func setAlertVolume(_ vol: Int) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "set volume alert volume \(vol)"]
        try? process.run()
    }
    
    func restoreAlertVolume() {
        setAlertVolume(originalAlertVolume)
    }
}
