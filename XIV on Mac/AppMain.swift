//
//  AppMain.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import AppMover
import Cocoa
import Sparkle
import SwiftUI
import XIVLauncher

@main class XIVOnMac: App {
    private var launchController: LaunchController = .init()

    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    required init() {}

    var body: some Scene {
        WindowGroup {
            LaunchWindowContent()
                .environmentObject(launchController)
                .environmentObject(launchController.installerController)
                .environmentObject(launchController.patchController)
                .environmentObject(launchController.repairController)
                .onAppear {
                    DispatchQueue.global(qos: .userInteractive).async {
                        self.launchController.checkBoot()
                    }
                }
        }
        .commands {
            CommandGroup(after: CommandGroupPlacement.appInfo) {
                Button("MENU_CHECK_FOR_UPDATES") {
                    self.appDelegate.sparkle?.checkForUpdates(nil)
                }
                Divider()
                Button("MENU_SETTINGS") {
                    self.appDelegate.openSettings()
                }
                .keyboardShortcut(",", modifiers: [.command])
                Divider()
            }
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                Button("MENU_OPEN") {
                    self.appDelegate.explorer(self)
                }
                .keyboardShortcut("o", modifiers: [.command])
                Button("MENU_OPEN_INSTALL_FOLDER") {
                    self.appDelegate.openPrefix(self)
                }
                .keyboardShortcut("i", modifiers: [.command])
                Button("MENU_SELECT_GAME_PATH") {
                    self.appDelegate.selectGamePath(self)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                Button("MENU_REPAIR_GAME") {
                    self.launchController.doRepair()
                }
                .keyboardShortcut("r", modifiers: [.command])
                Divider()
            }
            CommandMenu("MENU_TOOLS") {
                Button("MENU_TROUBLESHOOTING") {
                    self.appDelegate.openFirstAid()
                }
                Button("MENU_EDIT_REGISTRY") {
                    self.appDelegate.regedit(self)
                }
                Button("MENU_WINE_CONFIG") {
                    self.appDelegate.winecfg(self)
                }
                Divider()
                Button("MENU_CLI") {
                    self.appDelegate.cmd(self)
                }
            }
            CommandMenu("MENU_ADD_ONS") {
                Button("MENU_ANAMNESIS_START") {
                    self.appDelegate.startAnamnesis(self)
                }
                Divider()
                Button("MENU_IINACT_START") {
                    self.appDelegate.startIINACT(self)
                }
                if IINACT.autoLaunch {
                    Button("MENU_IINACT_AUTOSTART_DISABLE") {
                        IINACT.autoLaunch = false
                    }
                }
                else {
                    Button("MENU_IINACT_AUTOSTART_ENABLE") {
                        IINACT.autoLaunch = true
                    }
                }
                Divider()
                Button("MENU_ACT_START") {
                    self.appDelegate.startACT(self)
                }
                if ACT.autoLaunch {
                    Button("MENU_ACT_AUTOSTART_DISABLE") {
                        ACT.autoLaunch = false
                    }
                }
                else {
                    Button("MENU_ACT_AUTOSTART_ENABLE") {
                        ACT.autoLaunch = true
                    }
                }
                Divider()
                Button("MENU_BUNNY_START") {
                    self.appDelegate.startBH(self)
                }
                if BunnyHUD.autoLaunch == true {
                    Button("MENU_BUNNY_AUTOSTART_DISABLE") {
                        BunnyHUD.autoLaunch = false
                    }
                }
                else {
                    Button("MENU_BUNNY_AUTOSTART_ENABLE") {
                        BunnyHUD.autoLaunch = true
                    }
                }
            }
            CommandMenu("MENU_INSTALL") {
                Menu("MENU_MSVCPP") {
                    Button("x86") {
                        self.appDelegate.installMSVC32(self)
                    }
                    Button("x64") {
                        self.appDelegate.installMSVC64(self)
                    }
                }
                Menu("MENU_DOTNET_4") {
                    Button("4.0") {
                        self.appDelegate.installDotNet40(self)
                    }
                    Button("4.6.2") {
                        self.appDelegate.installDotNet462(self)
                    }
                    Button("4.7.2") {
                        self.appDelegate.installDotNet472(self)
                    }
                    Button("4.8") {
                        self.appDelegate.installDotNet48(self)
                    }
                }
                Button("MENU_DOTNET_6") {
                    self.appDelegate.installDotNet60(self)
                }
                Button("MENU_DOTNET_7") {
                    self.appDelegate.installDotNet70(self)
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate, ObservableObject {
    public var sparkle: SPUStandardUpdaterController?
    private var settingsWindow: NSWindow?
    private var firstAidWindow: NSWindow?

    func applicationWillUpdate(_ notification: Notification) {
        // Dumb hack because there doesn't appear to be a way to remove an entire menu tree in SwiftUI currently
        // Needs to be in Update rather than a one-time method like will/did finish launching because the menu gets rebuilt often.
        if let menu = NSApplication.shared.mainMenu {
            menu.items.removeAll { $0.title == "View" }
        }
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        sparkle = SPUStandardUpdaterController(updaterDelegate: self, userDriverDelegate: nil)
        Settings.syncToXL()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!
        let storagePath = FileManager.default.fileSystemRepresentation(withPath: Util.applicationSupport.path)
        initXL("XIV on Mac \(version) build \(build)", storagePath, Settings.verboseLogging)
        Wine.setup()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Do this first so that nothing loads data or otherwise touches the prefix first!
        let migrated = PrefixMigrator.migratePrefixIfNeeded()
        checkForRosetta()
        checkGPUSupported()
        Wine.boot()
        if migrated {
            // The final piece of migration has to happen after wine is ready for use.
            PrefixMigrator.migrateWineRegistrySettings()
        }
        if let sparkle = sparkle {
            sparkle.updater.checkForUpdatesInBackground()
        }
        Util.make(dir: Util.cache.path)
#if DEBUG
        Log.debug("Running in debug mode")
#else
        AppMover.moveIfNecessary()
#endif
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Wine.kill()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return true
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        Wine.launch(command: "\"\(filename)\"")
        return true
    }
    
    func checkForRosetta() {
        if Util.getXOMRuntimeEnvironment() == .appleSiliconNative { // No need to do any of this on Intel, and if we're already in Rosetta the answer is self-evident
            if !Wine.rosettaInstalled {
                let alert: NSAlert = .init()
                alert.messageText = NSLocalizedString("ROSETTA_REQUIRED", comment: "")
                alert.informativeText = NSLocalizedString("ROSETTA_REQUIRED_INFORMATIVE", comment: "")
                alert.alertStyle = .warning
                alert.addButton(withTitle: NSLocalizedString("ROSETTA_REQUIRED_INSTALL_BUTTON", comment: ""))
                alert.addButton(withTitle: NSLocalizedString("ROSETTA_REQUIRED_CANCEL_BUTTON", comment: ""))
                let result = alert.runModal()
                if result == .alertFirstButtonReturn {
                    let rosettaCommand = Bundle.main.url(forResource: "installRosetta", withExtension: "command")
                    if rosettaCommand != nil {
                        // We could launch Terminal directly, but this should work more nicely for people who use 3rd party
                        // terminal apps.
                        Util.launch(exec: URL(fileURLWithPath: "/usr/bin/open"), args: [rosettaCommand!.path])
                    }
                }
            }
        }
    }
    
    func checkGPUSupported() {
        if !Util.supportedGPU() {
            let alert: NSAlert = .init()
            alert.messageText = NSLocalizedString("UNSUPPORTED_GPU", comment: "")
            alert.informativeText = NSLocalizedString("UNSUPPORTED_GPU_INFORMATIVE", comment: "")
            alert.alertStyle = .critical
            alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("SEE_COMPATABILITY_BUTTON", comment: ""))
            alert.icon = NSImage(named: "CfgCheckProbFailed.tiff")
            let result = alert.runModal()
            if result == .alertSecondButtonReturn {
                NSWorkspace.shared.open(URL(string: "https://www.xivmac.com/compatibility-database")!)
            }
        }
    }
    
    func openPrefix(_ sender: Any) {
        NSWorkspace.shared.open(Util.applicationSupport)
    }
    
    func startAnamnesis(_ sender: Any) {
        Anamnesis.launch()
    }
    
    func startACT(_ sender: Any) {
        ACT.launch()
    }
    
    func startIINACT(_ sender: Any) {
        IINACT.launch()
    }
    
    func startBH(_ sender: Any) {
        BunnyHUD.launch()
    }
    
    func installDXVK(_ sender: Any) {
        Dxvk.install()
    }
    
    func installMSVC32(_ sender: Any) {
        Dotnet.installMSVC32()
    }
    
    func installMSVC64(_ sender: Any) {
        Dotnet.installMSVC64()
    }
    
    func installDotNet40(_ sender: Any) {
        Dotnet.installDotNet40()
    }
    
    func installDotNet462(_ sender: Any) {
        Dotnet.installDotNet462()
    }
    
    func installDotNet472(_ sender: Any) {
        Dotnet.installDotNet472()
    }
    
    func installDotNet48(_ sender: Any) {
        Dotnet.installDotNet48()
    }
    
    func installDotNet60(_ sender: Any) {
        Dotnet.installDotNet607()
    }
    
    func installDotNet70(_ sender: Any) {
        Dotnet.installDotNet702()
    }
    
    func regedit(_ sender: Any) {
        Wine.launch(command: "regedit")
    }
    
    func winecfg(_ sender: Any) {
        Wine.launch(command: "winecfg")
    }
    
    func explorer(_ sender: Any) {
        Wine.launch(command: "explorer")
    }
    
    func cmd(_ sender: Any) {
        Wine.launch(command: "wineconsole")
    }
    
    func selectGamePath(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.title = NSLocalizedString("SELECT_GAME_PATH_PANEL_TITLE", comment: "")
        openPanel.subtitle = NSLocalizedString("SELECT_GAME_PATH_PANEL_SUBTITLE", comment: "")
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = true
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.begin { response in
            if response == .OK {
                if InstallerController.isValidGameDirectory(gamePath: openPanel.url!.path) {
                    Settings.gamePath = openPanel.url!
                    openPanel.close()
                    return
                }
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("SELECT_GAME_PATH_ERROR_MESSAGE", comment: "")
                alert.informativeText = NSLocalizedString("SELECT_GAME_PATH_ERROR_INFORMATIVE", comment: "")
                alert.alertStyle = .warning
                alert.addButton(withTitle: NSLocalizedString("BUTTON_YES", comment: ""))
                alert.addButton(withTitle: NSLocalizedString("BUTTON_NO", comment: ""))
                if alert.runModal() == .alertFirstButtonReturn {
                    Settings.gamePath = openPanel.url!
                }
                openPanel.close()
            }
        }
    }
    
    func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsView().createNewWindow(title: NSLocalizedString("SETTINGS_WINDOW_TITLE", comment: ""), delegate: nil)
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func openFirstAid() {
        if firstAidWindow == nil {
            firstAidWindow = FirstAidView().createNewWindow(title: NSLocalizedString("FIRSTAID_WINDOW_TITLE", comment: ""), delegate: nil)
        }
        firstAidWindow?.makeKeyAndOrderFront(nil)
    }
}
