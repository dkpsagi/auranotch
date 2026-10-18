import Cocoa
import SwiftUI

public class NotchPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        self.isMovable = false
        self.isMovableByWindowBackground = false
        self.acceptsMouseMovedEvents = true
        self.hidesOnDeactivate = false
    }

    public override var canBecomeKey: Bool {
        return true
    }

    public override var canBecomeMain: Bool {
        return true
    }
}

public class NotchWindowController: NSResponder, ObservableObject {
    public static let shared = NotchWindowController()

    public var panel: NotchPanel?
    private var trackingArea: NSTrackingArea?
    private var hoverTimer: Timer?
    private var appState = AppState.shared

    public override init() {
        super.init()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func setupWindow() {
        guard let screen = NSScreen.main else { return }
        
        let screenRect = screen.frame
        let notchHeight: CGFloat = screen.safeAreaInsets.top > 0 ? screen.safeAreaInsets.top : 34.0
        let closedWidth: CGFloat = appState.notchWidth
        let closedHeight: CGFloat = max(notchHeight, 34.0)

        // Center notch at the top of the main display
        let initialX = screenRect.midX - (closedWidth / 2.0)
        let initialY = screenRect.maxY - closedHeight

        let windowRect = NSRect(x: initialX, y: initialY, width: closedWidth, height: closedHeight)
        let panel = NotchPanel(contentRect: windowRect)

        let hostingView = NSHostingView(rootView: NotchRootView())
        panel.contentView = hostingView
        panel.orderFrontRegardless()

        self.panel = panel
        panel.makeKeyAndOrderFront(nil)
        self.setupTrackingArea()
        self.setupGlobalShortcuts()

        // Auto-expand on launch so the user sees the HUD immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.expand()
        }
    }

    public func updateWindowFrame(animated: Bool = true) {
        guard let panel = panel, let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        let isExpanded = appState.isExpanded

        let targetWidth = isExpanded ? appState.expandedWidth : appState.notchWidth
        let targetHeight = isExpanded ? appState.expandedHeight : max(screen.safeAreaInsets.top, 34.0)

        let targetX = screenRect.midX - (targetWidth / 2.0)
        let targetY = screenRect.maxY - targetHeight

        let targetRect = NSRect(x: targetX, y: targetY, width: targetWidth, height: targetHeight)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.32
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                panel.animator().setFrame(targetRect, display: true)
            }
        } else {
            panel.setFrame(targetRect, display: true)
        }
    }

    public func toggleExpand() {
        if appState.isExpanded {
            collapse()
        } else {
            expand()
        }
    }

    public func expand() {
        guard !appState.isExpanded else { return }
        hoverTimer?.invalidate()
        hoverTimer = nil
        appState.isExpanded = true
        updateWindowFrame(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) { [weak self] in
            self?.setupTrackingArea()
        }
    }

    public func collapse() {
        guard appState.isExpanded else { return }
        hoverTimer?.invalidate()
        hoverTimer = nil
        appState.isExpanded = false
        updateWindowFrame(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) { [weak self] in
            self?.setupTrackingArea()
        }
    }

    private func setupTrackingArea() {
        guard let panel = panel, let contentView = panel.contentView else { return }
        if let existing = trackingArea {
            contentView.removeTrackingArea(existing)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect]
        let area = NSTrackingArea(rect: contentView.bounds, options: options, owner: self, userInfo: nil)
        contentView.addTrackingArea(area)
        self.trackingArea = area
    }

    public override func mouseEntered(with event: NSEvent) {
        guard appState.triggerMode == .hover else { return }
        hoverTimer?.invalidate()
        let delay = appState.hoverDelayMs / 1000.0
        hoverTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.expand()
            }
        }
    }

    public override func mouseExited(with event: NSEvent) {
        hoverTimer?.invalidate()
        hoverTimer = nil
        // Generous grace buffer to prevent glitching/jitter when navigating around controls
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { [weak self] in
            guard let self = self, let panel = self.panel else { return }
            let mouseLoc = NSEvent.mouseLocation
            let bufferFrame = panel.frame.insetBy(dx: -24, dy: -24)
            if !bufferFrame.contains(mouseLoc) {
                self.collapse()
            }
        }
    }

    private func setupGlobalShortcuts() {
        // Register local & global key monitors for ⌥ + Space / ⌥ + N
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.option) && event.keyCode == 45 { // 'N' key
                self?.toggleExpand()
                return nil
            }
            return event
        }
    }
}
