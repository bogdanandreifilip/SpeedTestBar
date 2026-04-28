import AppKit
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Synchronize the UI state with the actual system service status on launch
        UserDefaults.standard.set(SMAppService.mainApp.status == .enabled, forKey: "launchAtLogin")
        
        if let button = statusItem?.button {
            let icon = NSImage(named: "MenuBarIcon")
            icon?.isTemplate = false
            button.image = icon
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
        
        // Observe changes to refresh the menu bar title
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTitle), name: NSNotification.Name("UpdateMenuBarTitle"), object: nil)

        // Initial title update
        updateMenuBarTitle()

        let contentView = ContentView()
        popover.contentViewController = NSHostingController(rootView: contentView)
        popover.contentSize = NSSize(width: 260, height: 350)
        popover.behavior = .transient
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button, let event = NSApp.currentEvent else { return }

        // Check if the trigger was a right-click or a Control-click
        if event.type == .rightMouseUp || (event.type == .leftMouseUp && event.modifierFlags.contains(.control)) {
            let menu = NSMenu()
            
            let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
            // Read from UserDefaults so the checkmark reflects the UI state immediately
            launchItem.state = UserDefaults.standard.bool(forKey: "launchAtLogin") ? .on : .off
            launchItem.target = self
            menu.addItem(launchItem)
            
            menu.addItem(NSMenuItem.separator())
            
            menu.addItem(NSMenuItem(title: "Quit SpeedTestBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusItem?.menu = menu
            button.performClick(nil)
            statusItem?.menu = nil // Reset so subsequent left-clicks show the popover
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc func refreshTitle() {
        updateMenuBarTitle()
    }

    private func updateMenuBarTitle() {
        let showDL = UserDefaults.standard.bool(forKey: "showDownloadInMenuBar")
        let showUL = UserDefaults.standard.bool(forKey: "showUploadInMenuBar")
        let showPing = UserDefaults.standard.bool(forKey: "showPingInMenuBar")

        let dlValue = UserDefaults.standard.double(forKey: "lastDownload")
        let ulValue = UserDefaults.standard.double(forKey: "lastUpload")
        let pingValue = UserDefaults.standard.double(forKey: "lastPing")

        var components: [String] = []
        if showDL && dlValue > 0 { components.append("↓\(String(format: "%.1f", dlValue))") }
        if showUL && ulValue > 0 { components.append("↑\(String(format: "%.1f", ulValue))") }
        if showPing && pingValue > 0 { components.append("\(Int(pingValue))ms") }

        DispatchQueue.main.async {
            // If components is empty, title becomes "", showing only the icon
            self.statusItem?.button?.title = components.joined(separator: " ")
        }
    }

    @objc func toggleLaunchAtLogin() {
        do {
            let isCurrentlyEnabled = SMAppService.mainApp.status == .enabled
            if isCurrentlyEnabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
            
            // Update UserDefaults to trigger UI refreshes in SwiftUI
            UserDefaults.standard.set(!isCurrentlyEnabled, forKey: "launchAtLogin")
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}
