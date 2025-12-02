//
//  AppDelegate.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import AppMover
import Cocoa
import KeyboardShortcuts
import Sparkle
import UserNotifications
import XIVLauncher

@main class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
    private var settingsWindow: NSWindow?
    private var firstAidWindow: NSWindow?
    private var launchWinController: NSWindowController?
    private var benchmarkWindow: NSWindow?
    private var screenCapture: ScreenCapture?
    @IBOutlet private var sparkle: SPUStandardUpdaterController!
    @IBOutlet private var bhAutoLaunch: NSMenuItem!

    func applicationWillFinishLaunching(_ notification: Notification) {
        var signalSet = sigset_t()
        sigemptyset(&signalSet)
        sigaddset(&signalSet, SIGUSR1)
        if pthread_sigmask(SIG_BLOCK, &signalSet, nil) != 0 {
            perror("pthread_sigmask")
        }
        Settings.syncToXL()
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString")!
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!
        let storagePath = FileManager.default.fileSystemRepresentation(
            withPath: Util.applicationSupport.path)
        registerWineAppWillActivateNotification()
        initXL(
            "XIV on Mac \(version) build \(build)", storagePath,
            Settings.verboseLogging, Frontier.frontierURLTemplate)
        Wine.setup()
        GraphicsInstaller.ensureBackend()
    }

    func registerWineAppWillActivateNotification() {
        if #available(macOS 14.0, *) {
            DistributedNotificationCenter.default().addObserver(
                self,
                selector: #selector(wineAppWillActivate(_:)),
                name: Notification.Name("WineAppWillActivateNotification"),
                object: nil,
                suspensionBehavior: .deliverImmediately
            )
        }
    }

    @objc func wineAppWillActivate(_ notification: Notification) {
        guard
            let winePID = notification.userInfo?["ActivatingAppPID"] as? Int32,
            let wineApp = NSRunningApplication(processIdentifier: winePID)
        else { return }

        if #available(macOS 14.0, *) {
            Log.debug("yielding activation to \(wineApp)")
            NSApp.yieldActivation(to: wineApp)
            wineApp.activate(from: NSRunningApplication.current, options: [])
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Do this first so that nothing loads data or otherwise touches the prefix first!
        let migrated = PrefixMigrator.migratePrefixIfNeeded()
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        launchWinController =
            storyboard.instantiateController(withIdentifier: "LaunchWindow")
            as? NSWindowController
        launchWinController?.showWindow(self)
        bhAutoLaunch.state = BunnyHUD.autoLaunch ? .on : .off
        checkForRosetta()
        checkGPUSupported()
        Wine.boot()
        if migrated {
            // The final piece of migration has to happen after wine is ready for use.
            PrefixMigrator.migrateWineRegistrySettings()
        }
        // TEMPORARILY DISABLED: Auto-update check
        // To re-enable: Uncomment the line below
        // sparkle.updater.checkForUpdatesInBackground()
        Util.make(dir: Util.cache.path)
        #if DEBUG
            Log.debug("Running in debug mode")
        #else
            AppMover.moveIfNecessary()
        #endif
        UNUserNotificationCenter.current().requestAuthorization(options: [
            .alert
        ]) {
            (permissionGranted, error) in
            Log.information(
                "Permission not granted for Alerts: \(String(describing: error))"
            )
        }

        screenCapture = ScreenCapture()
        KeyboardShortcuts.onKeyDown(for: .toggleVideoCapture) { [self] in
            screenCapture?.toggleScreenCapture()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Wine.kill()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool
    {
        return true
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication, hasVisibleWindows flag: Bool
    ) -> Bool {
        if !flag {
            launchWinController?.showWindow(self)
        }
        return true
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool
    {
        Wine.launch(command: "\"\(filename)\"")
        return true
    }

    @MainActor func checkForRosetta() {
        if Util.getXOMRuntimeEnvironment() == .appleSiliconNative {  // No need to do any of this on Intel, and if we're already in Rosetta the answer is self-evident
            if !Util.rosettaIsInstalled() {
                let alert: NSAlert = NSAlert()
                alert.messageText = NSLocalizedString(
                    "ROSETTA_REQUIRED", comment: "")
                alert.informativeText = NSLocalizedString(
                    "ROSETTA_REQUIRED_INFORMATIVE", comment: "")
                alert.alertStyle = .warning
                alert.addButton(
                    withTitle: NSLocalizedString(
                        "ROSETTA_REQUIRED_INSTALL_BUTTON", comment: ""))
                alert.addButton(
                    withTitle: NSLocalizedString(
                        "ROSETTA_REQUIRED_CANCEL_BUTTON", comment: ""))
                let result = alert.runModal()
                if result == .alertFirstButtonReturn {
                    Util.launch(
                        exec: URL(fileURLWithPath: "/usr/sbin/softwareupdate"),
                        args: ["--install-rosetta", "--agree-to-license"],
                        blocking: true)
                }
            }
        }
    }

    @MainActor func checkGPUSupported() {
        if !Util.supportedGPU() {
            let alert: NSAlert = .init()
            alert.messageText = NSLocalizedString(
                "UNSUPPORTED_GPU", comment: "")
            alert.informativeText = NSLocalizedString(
                "UNSUPPORTED_GPU_INFORMATIVE", comment: "")
            alert.alertStyle = .critical
            alert.addButton(
                withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
            alert.addButton(
                withTitle: NSLocalizedString(
                    "SEE_COMPATABILITY_BUTTON", comment: ""))
            alert.icon = NSImage(named: "CfgCheckProbFailed.tiff")
            let result = alert.runModal()
            if result == .alertSecondButtonReturn {
                NSWorkspace.shared.open(
                    URL(
                        string: "https://www.xivmac.com/compatibility-database")!
                )
            }
        }
    }

    @IBAction func openPrefix(_ sender: Any) {
        NSWorkspace.shared.open(Util.applicationSupport)
    }

    @IBAction func startBH(_ sender: Any) {
        BunnyHUD.launch()
    }

    @IBAction func toggleBH(_ sender: Any) {
        BunnyHUD.autoLaunch = !BunnyHUD.autoLaunch
        bhAutoLaunch.state = BunnyHUD.autoLaunch ? .on : .off
    }

    @IBAction func regedit(_ sender: Any) {
        Wine.launch(command: "regedit")
    }

    @IBAction func winecfg(_ sender: Any) {
        Wine.launch(command: "winecfg")
    }

    @IBAction func explorer(_ sender: Any) {
        Wine.launch(command: "explorer")
    }

    @IBAction func cmd(_ sender: Any) {
        Wine.launch(command: "wineconsole")
    }

    @IBAction func appSettings(_ sender: Any) {
        if settingsWindow == nil {
            settingsWindow = SettingsView().createNewWindow(
                title: NSLocalizedString("SETTINGS_WINDOW_TITLE", comment: ""),
                delegate: nil)
        }
        settingsWindow?.makeKeyAndOrderFront(sender)
    }

    @IBAction func openFirstAid(_ sender: Any) {
        if firstAidWindow == nil {
            firstAidWindow = FirstAidView().createNewWindow(
                title: NSLocalizedString("FIRSTAID_WINDOW_TITLE", comment: ""),
                delegate: nil)
        }
        firstAidWindow?.makeKeyAndOrderFront(sender)
    }

    @IBAction func selectGamePath(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.title = NSLocalizedString(
            "SELECT_GAME_PATH_PANEL_TITLE", comment: "")
        openPanel.subtitle = NSLocalizedString(
            "SELECT_GAME_PATH_PANEL_SUBTITLE", comment: "")
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = true
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.begin { response in
            if response == .OK {
                if InstallerController.isValidGameDirectory(
                    gamePath: openPanel.url!.path)
                {
                    Settings.gamePath = openPanel.url!
                    openPanel.close()
                    return
                }
                let alert = NSAlert()
                alert.messageText = NSLocalizedString(
                    "SELECT_GAME_PATH_ERROR_MESSAGE", comment: "")
                alert.informativeText = NSLocalizedString(
                    "SELECT_GAME_PATH_ERROR_INFORMATIVE", comment: "")
                alert.alertStyle = .warning
                alert.addButton(
                    withTitle: NSLocalizedString("BUTTON_YES", comment: ""))
                alert.addButton(
                    withTitle: NSLocalizedString("BUTTON_NO", comment: ""))
                if alert.runModal() == .alertFirstButtonReturn {
                    Settings.gamePath = openPanel.url!
                }
                openPanel.close()
            }
        }
    }

    @IBAction func startBenchmark(_ sender: Any) {
        if benchmarkWindow == nil {
            benchmarkWindow = BenchmarkView().createNewWindow(
                title: NSLocalizedString("BENCHMARK_WINDOW_TITLE", comment: ""),
                delegate: nil)
        }
        benchmarkWindow?.makeKeyAndOrderFront(sender)
    }
}
