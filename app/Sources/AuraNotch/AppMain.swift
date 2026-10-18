import Cocoa
import SwiftUI

@main
public class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    private var windowController = NotchWindowController.shared

    public static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory application so it stays discreet in the background
        NSApp.setActivationPolicy(.accessory)

        // Setup menu bar status item with authentic monochrome notch icon
        setupStatusItem()

        // Setup Notch Window on the main screen
        DispatchQueue.main.async { [weak self] in
            self?.windowController.setupWindow()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = createMonochromeNotchIcon()
            button.toolTip = "AuraNotch Pro (⌥+N)"
            button.target = self
            button.action = #selector(statusBarClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle AuraNotch (⌥+N)", action: #selector(toggleNotch), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Hardware Mic Mute (Toggle)", action: #selector(toggleMic), keyEquivalent: "m"))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "License Status...", action: #selector(openLicenseModal), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "About AuraNotch", action: #selector(openAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit AuraNotch", action: #selector(quitApp), keyEquivalent: "q"))
        self.statusMenu = menu
    }

    private func createMonochromeNotchIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            ctx.setAllowsAntialiasing(true)
            ctx.setShouldAntialias(true)

            // Sleek MacBook Display Notch silhouette (vertically centered in 18x18 frame)
            let notchRect = CGRect(x: 1.5, y: 4.5, width: 15.0, height: 9.0)
            let notchPath = CGPath(roundedRect: notchRect, cornerWidth: 2.5, cornerHeight: 2.5, transform: nil)

            ctx.setFillColor(NSColor.black.cgColor)
            ctx.addPath(notchPath)
            ctx.fillPath()

            // True transparent aperture punch-outs via .clear blend mode
            ctx.setBlendMode(.clear)

            // Ambient light sensor micro cutout (left)
            let sensorRect = CGRect(x: 3.8, y: 8.4, width: 1.4, height: 1.4)
            ctx.fillEllipse(in: sensorRect)

            // Main FaceTime camera lens cutout (center)
            let lensRect = CGRect(x: 7.5, y: 7.5, width: 3.0, height: 3.0)
            ctx.fillEllipse(in: lensRect)

            // Status LED micro indicator cutout (right)
            let ledRect = CGRect(x: 12.4, y: 8.3, width: 1.6, height: 1.6)
            ctx.fillEllipse(in: ledRect)

            ctx.setBlendMode(.normal)
            return true
        }
        image.isTemplate = true
        return image
    }

    @objc private func statusBarClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || (event?.modifierFlags.contains(.control) == true) {
            if let menu = statusMenu {
                statusItem?.menu = menu
                statusItem?.button?.performClick(nil)
                statusItem?.menu = nil
            }
        } else {
            toggleNotch()
        }
    }

    @objc private func toggleNotch() {
        windowController.toggleExpand()
    }

    @objc private func toggleMic() {
        AppState.shared.toggleMicMute()
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
