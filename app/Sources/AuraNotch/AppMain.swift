import Cocoa
import SwiftUI

@main
public class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var windowController = NotchWindowController.shared

    public static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory application so it doesn't clutter Dock unless desired
        NSApp.setActivationPolicy(.accessory)

        // Setup menu bar status item
        setupStatusItem()

        // Setup Notch Window on the main screen
        DispatchQueue.main.async { [weak self] in
            self?.windowController.setupWindow()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles.rectangle.stack", accessibilityDescription: "AuraNotch")
            button.action = #selector(statusBarClicked)
            button.target = self
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle AuraNotch (⌥+N)", action: #selector(toggleNotch), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "License & Activation...", action: #selector(openLicenseModal), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "About AuraNotch", action: #selector(openAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit AuraNotch", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func statusBarClicked() {
        toggleNotch()
    }

    @objc private func toggleNotch() {
        windowController.toggleExpand()
    }

    @objc private func openLicenseModal() {
        LicenseManager.shared.showActivationModal = true
        windowController.expand()
    }

    @objc private func openSettings() {
        AppState.shared.activeTab = .settings
        windowController.expand()
    }

    @objc private func openAbout() {
        let alert = NSAlert()
        alert.messageText = "AuraNotch Pro"
        alert.informativeText = "Version 2.5.0\nThe intelligent camera notch command center for macOS.\n100% on-device, private by design."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
