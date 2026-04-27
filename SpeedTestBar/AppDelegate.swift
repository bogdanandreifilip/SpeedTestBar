import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "wifi", accessibilityDescription: nil)
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        if let button = statusItem?.button {
            let icon = NSImage(named: "MenuBarIcon")
            icon?.isTemplate = false
            button.image = icon
            button.action = #selector(togglePopover)
            button.target = self
        }

        let contentView = ContentView()
        popover.contentViewController = NSHostingController(rootView: contentView)
        popover.contentSize = NSSize(width: 260, height: 200)
        popover.behavior = .transient
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
