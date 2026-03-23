import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var selectedPDFURL: URL?
    weak var mainWindow: NSWindow?

    func handleIncomingFilePaths(_ filePaths: [String]) {
        handleIncomingURLs(filePaths.map { URL(fileURLWithPath: $0) })
    }

    func handleIncomingURLs(_ urls: [URL]) {
        guard let pdfURL = urls.first(where: Self.isPDF(_:)) else {
            return
        }

        selectedPDFURL = pdfURL
        presentMainWindow()
    }

    func setSelectedPDF(from url: URL?) {
        guard let url, Self.isPDF(url) else {
            return
        }

        selectedPDFURL = url
    }

    func clearSelectedPDF() {
        selectedPDFURL = nil
    }

    func presentMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        let window = mainWindow ?? NSApp.windows.first(where: { $0.className == "SwiftUI.AppKitWindow" })
        guard let window else {
            return
        }

        mainWindow = window

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
    }

    private static func isPDF(_ url: URL) -> Bool {
        if let type = UTType(filenameExtension: url.pathExtension) {
            return type.conforms(to: .pdf)
        }

        return url.pathExtension.lowercased() == "pdf"
    }
}

extension Bundle {
    var releaseVersionNumber: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

@main
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private enum MenuIdentifier {
        static let app = "spotlesspdf.menu.app"
        static let language = "spotlesspdf.menu.language"
    }

    private let defaultWindowSize = NSSize(width: 640, height: 420)
    private var mainWindowController: NSWindowController?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMenusIfNeeded()
        presentMainWindow()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        configureMenusIfNeeded()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        AppState.shared.handleIncomingFilePaths(filenames)
        sender.reply(toOpenOrPrint: .success)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        AppState.shared.handleIncomingURLs(urls)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        presentMainWindow()
        return false
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        sender.frame.size
    }

    private func presentMainWindow() {
        let window = ensureMainWindow()
        AppState.shared.mainWindow = window
        mainWindowController?.showWindow(nil)
        AppState.shared.presentMainWindow()
    }

    private func ensureMainWindow() -> NSWindow {
        if let existingWindow = mainWindowController?.window {
            return existingWindow
        }

        let rootView = ContentView()
            .environment(\.locale, AppLocalization.locale)
            .environment(\.layoutDirection, AppLocalization.layoutDirection)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)

        window.title = "SpotlessPDF"
        window.delegate = self
        window.styleMask.insert(.fullSizeContentView)
        window.styleMask.remove(.resizable)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.setContentSize(defaultWindowSize)
        window.contentMinSize = defaultWindowSize
        window.contentMaxSize = defaultWindowSize
        window.collectionBehavior.subtract([
            .fullScreenPrimary,
            .fullScreenAuxiliary,
            .fullScreenAllowsTiling
        ])
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        centerWindow(window)

        let controller = NSWindowController(window: window)
        controller.shouldCascadeWindows = false
        mainWindowController = controller

        return window
    }

    private func centerWindow(_ window: NSWindow) {
        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let visibleFrame = screen?.visibleFrame else {
            window.center()
            return
        }

        let frame = window.frame
        let origin = NSPoint(
            x: visibleFrame.midX - (frame.width / 2),
            y: visibleFrame.midY - (frame.height / 2)
        )
        window.setFrameOrigin(origin)
    }

    private func configureMenusIfNeeded() {
        if !isUsingCustomMainMenu() {
            NSApp.mainMenu = makeMainMenu()
        }

        NSApp.helpMenu = nil
        NSApp.windowsMenu = nil
        DispatchQueue.main.async { [weak self] in
            self?.restoreCustomMainMenuIfNeeded()
        }
    }

    private func makeMainMenu() -> NSMenu {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        appMenuItem.identifier = NSUserInterfaceItemIdentifier(MenuIdentifier.app)
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu(title: "SpotlessPDF")
        appMenuItem.submenu = appMenu

        appMenu.addItem(
            withTitle: L10n.appMenuAbout,
            action: #selector(showAboutPanel),
            keyEquivalent: ""
        )
        appMenu.items.last?.target = self
        appMenu.addItem(.separator())

        let servicesItem = NSMenuItem(title: L10n.appMenuServices, action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu(title: L10n.appMenuServices)
        servicesItem.submenu = servicesMenu
        appMenu.addItem(servicesItem)
        NSApp.servicesMenu = servicesMenu

        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: L10n.appMenuHide,
            action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "h"
        )
        appMenu.addItem(
            withTitle: L10n.appMenuHideOthers,
            action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h"
        ).keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(
            withTitle: L10n.appMenuShowAll,
            action: #selector(NSApplication.unhideAllApplications(_:)),
            keyEquivalent: ""
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: L10n.appMenuQuit,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        let languageMenuItem = NSMenuItem(
            title: AppLocalization.languageMenuTitle(),
            action: nil,
            keyEquivalent: ""
        )
        languageMenuItem.identifier = NSUserInterfaceItemIdentifier(MenuIdentifier.language)
        mainMenu.addItem(languageMenuItem)

        let languageMenu = NSMenu(title: AppLocalization.languageMenuTitle())
        languageMenuItem.submenu = languageMenu

        let automaticItem = NSMenuItem(
            title: AppLocalization.automaticMenuTitle(),
            action: #selector(selectAutomaticLanguage),
            keyEquivalent: ""
        )
        automaticItem.target = self
        automaticItem.state = AppLocalization.usesOverrideLanguage ? .off : .on
        languageMenu.addItem(automaticItem)
        languageMenu.addItem(.separator())

        for option in AppLocalization.supportedLanguageOptions {
            let item = NSMenuItem(
                title: option.title,
                action: #selector(selectLanguage(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = option.id
            item.state = AppLocalization.currentSelectionIdentifier == option.id ? .on : .off
            languageMenu.addItem(item)
        }

        return mainMenu
    }

    private func restoreCustomMainMenuIfNeeded() {
        guard !isUsingCustomMainMenu() else {
            NSApp.helpMenu = nil
            NSApp.windowsMenu = nil
            return
        }

        NSApp.mainMenu = makeMainMenu()
        NSApp.helpMenu = nil
        NSApp.windowsMenu = nil
    }

    private func isUsingCustomMainMenu() -> Bool {
        guard let mainMenu = NSApp.mainMenu else {
            return false
        }

        let allowedIdentifiers: Set<NSUserInterfaceItemIdentifier> = [
            NSUserInterfaceItemIdentifier(MenuIdentifier.app),
            NSUserInterfaceItemIdentifier(MenuIdentifier.language)
        ]
        let presentIdentifiers = Set(mainMenu.items.compactMap(\.identifier))
        return presentIdentifiers == allowedIdentifiers && mainMenu.items.count == 2
    }

    @objc private func selectAutomaticLanguage() {
        AppLocalization.setOverrideLanguageCode(nil)
        relaunchApplication()
    }

    @objc private func showAboutPanel() {
        let localizedVersion = L10n.aboutVersion(Bundle.main.releaseVersionNumber)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationVersion: localizedVersion
        ])
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let languageCode = sender.representedObject as? String else {
            return
        }

        AppLocalization.setOverrideLanguageCode(languageCode)
        relaunchApplication()
    }

    private func relaunchApplication() {
        let bundlePath = Bundle.main.bundlePath
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [
            "-c",
            """
            sleep 0.3
            open -n "$1"
            if [ -n "$2" ]; then
              sleep 0.4
              osascript -e 'tell application id "'"$2"'" to activate'
            fi
            """,
            "relaunch",
            bundlePath,
            bundleIdentifier
        ]

        do {
            try process.run()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                NSApp.terminate(nil)
            }
        } catch {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
