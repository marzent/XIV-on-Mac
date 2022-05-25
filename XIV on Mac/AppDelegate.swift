//
//  AppDelegate.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa
import Sparkle
import AppMover
import XIVLauncher

@main class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
    private var settingsWinController: NSWindowController?
    private var launchWinController: NSWindowController?
    private var firstAidWinController: NSWindowController?
    @IBOutlet private var sparkle: SPUStandardUpdaterController!
    @IBOutlet private var actAutoLaunch: NSMenuItem!
    @IBOutlet private var bhAutoLaunch: NSMenuItem!
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        Settings.syncToXL()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!
        initXL("XIV on Mac \(version) build \(build)", Util.applicationSupport.path)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        settingsWinController = storyboard.instantiateController(withIdentifier: "SettingsWindow") as? NSWindowController
        firstAidWinController = storyboard.instantiateController(withIdentifier: "FirstAidWindow") as? NSWindowController
        launchWinController = storyboard.instantiateController(withIdentifier: "LaunchWindow") as? NSWindowController
        launchWinController?.showWindow(self)
        actAutoLaunch.state = ACT.autoLaunch ? .on : .off
        bhAutoLaunch.state = ACT.autoLaunchBH ? .on : .off
        checkGPUSupported()
        Wine.setup()
        sparkle.updater.checkForUpdatesInBackground()
        Util.make(dir: Util.cache.path)
    #if DEBUG
        Log.debug("Running in debug mode")
    #else
        AppMover.moveIfNecessary()
    #endif
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        Wine.kill()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            launchWinController?.showWindow(self)
        }
        return true
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        Wine.launch(command: "\"\(filename)\"")
        return true
    }
    
    func checkForRosetta() {
        if (Util.getXOMRuntimeEnvironment() == .appleSiliconNative) {        // No need to do any of this on Intel, and if we're already in Rosetta the answer is self-evident
            if (!Util.rosettaIsInstalled())
            {
                let alert: NSAlert = NSAlert()
                alert.messageText = NSLocalizedString("ROSETTA_REQUIRED", comment: "")
                alert.informativeText = NSLocalizedString("ROSETTA_REQUIRED_INFORMATIVE", comment: "")
                alert.alertStyle = .warning
                alert.addButton(withTitle:NSLocalizedString("ROSETTA_REQUIRED_INSTALL_BUTTON", comment: ""))
                alert.addButton(withTitle:NSLocalizedString("ROSETTA_REQUIRED_CANCEL_BUTTON", comment: ""))
                let result = alert.runModal()
                if result == .alertFirstButtonReturn {
                    let rosettaCommand = Bundle.main.url(forResource: "installRosetta", withExtension: "command")
                    if (rosettaCommand != nil) {
                        // We could launch Terminal directly, but this should work more nicely for people who use 3rd party
                        // terminal apps.
                        Util.launch(exec: URL(fileURLWithPath: "/usr/bin/open"), args: [rosettaCommand!.path])
                    }
                }
            }
        }
    }
    
    func checkGPUSupported() {
        if (!Util.supportedGPU())
        {
            let alert: NSAlert = NSAlert()
            alert.messageText = NSLocalizedString("UNSUPPORTED_GPU", comment: "")
            alert.informativeText = NSLocalizedString("UNSUPPORTED_GPU_INFORMATIVE", comment: "")
            alert.alertStyle = .critical
            alert.addButton(withTitle:NSLocalizedString("OK_BUTTON", comment: ""))
            alert.addButton(withTitle:NSLocalizedString("SEE_COMPATABILITY_BUTTON", comment: ""))
            alert.icon = NSImage(named: "CfgCheckProbFailed.tiff")
            let result = alert.runModal()
            if result == .alertSecondButtonReturn {
                NSWorkspace.shared.open(URL(string: "https://www.xivmac.com/compatibility-database")!)
            }
        }
    }
    
    @IBAction func openPrefix(_ sender: Any) {
        NSWorkspace.shared.open(Util.applicationSupport)
    }
    
    @IBAction func startACT(_ sender: Any) {
        ACT.launch()
    }
    
    @IBAction func toggleACT(_ sender: Any) {
        ACT.autoLaunch = !ACT.autoLaunch
        actAutoLaunch.state = ACT.autoLaunch ? .on : .off
    }
    
    @IBAction func startBH(_ sender: Any) {
        ACT.launchBH()
    }
    
    @IBAction func toggleBH(_ sender: Any) {
        ACT.autoLaunchBH = !ACT.autoLaunchBH
        bhAutoLaunch.state = ACT.autoLaunchBH ? .on : .off
    }
    
    @IBAction func installDXVK(_ sender: Any) {
        Dxvk.install()
    }
    
    @IBAction func installMSVC32(_ sender: Any) {
        Dotnet.installMSVC32()
    }
    
    @IBAction func installMSVC64(_ sender: Any) {
        Dotnet.installMSVC64()
    }
    
    @IBAction func installDotNet40(_ sender: Any) {
        Dotnet.installDotNet40()
    }
    
    @IBAction func installDotNet462(_ sender: Any) {
        Dotnet.installDotNet462()
    }
    
    @IBAction func installDotNet472(_ sender: Any) {
        Dotnet.installDotNet472()
    }
    
    @IBAction func installDotNet48(_ sender: Any) {
        Dotnet.installDotNet48()
    }
    
    @IBAction func installDotNet(_ sender: Any) {
        Dotnet.install()
    }
    
    @IBAction func installGShade(_ sender: Any) {
        GShade.install()
    }
    
    @IBAction func manualGShade(_ sender: Any) {
        GShade.manual()
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
    
    @IBAction func dxvkSettings(_ sender: Any) {
        settingsWinController?.showWindow(self)
    }
	
    @IBAction func selectGamePath(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose the folder FFXIV is located in"
        if #available(macOS 11.0, *) {
            openPanel.subtitle = #"It should contain the folders "game" and "boot""#
        }
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = true
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.begin() { (response) in
            if response == .OK {
                if InstallerController.isValidGameDirectory(gamePath: openPanel.url!.path) {
                    Settings.gamePath = openPanel.url!
                    openPanel.close()
                    return
                }
                let alert = NSAlert()
                alert.messageText = "The folder you chose for your game install does not seem to be valid"
                alert.informativeText = "Do you still want to use it?"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Yes")
                alert.addButton(withTitle: "No")
                if alert.runModal() == .alertFirstButtonReturn {
                    Settings.gamePath = openPanel.url!
                }
                openPanel.close()
            }
        }
    }
    
    @IBAction func openFirstAid(_ sender: Any){
        firstAidWinController?.showWindow(self)
    }
    
}

