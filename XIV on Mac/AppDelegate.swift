//
//  AppDelegate.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa
import Sparkle


@main class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
    var settingsWinController: NSWindowController?
    @IBOutlet private var sparkle: SPUStandardUpdaterController!
    @IBOutlet private var actAutoLaunch: NSMenuItem!
    @IBOutlet private var bhAutoLaunch: NSMenuItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        actAutoLaunch.state = ACT.autoLaunch ? .on : .off
        bhAutoLaunch.state = ACT.autoLaunchBH ? .on : .off
        checkForRosetta()
        Steam.initAPI()
        sparkle.updater.checkForUpdatesInBackground()
        Util.make(dir: Wine.xomData.path)
        Util.make(dir: Util.cache.path)
        if DXVK.shouldUpdate {
            DispatchQueue.global(qos: .utility).async {
                DXVK.install()
            }
        }
        Wine.touchDocuments()
        settingsWinController = storyboard.instantiateController(withIdentifier: "SettingsWindow") as? NSWindowController
    }

    func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
        DXVK.shouldUpdate = true
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        Wine.kill()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        Wine.launch(args: [filename])
        return true
    }
    
    func checkForRosetta() {
    #if arch(arm64)
        // No need to do any of this on Intel.
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
    #endif
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
        DXVK.install()
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
        Wine.launch(args: ["regedit"])
    }
    
    @IBAction func winecfg(_ sender: Any) {
        Wine.launch(args: ["winecfg"])
    }
    
    @IBAction func explorer(_ sender: Any) {
        Wine.launch(args: ["explorer"])
    }
    
    @IBAction func cmd(_ sender: Any) {
        Wine.launch(args: ["wineconsole"])
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
                    FFXIVSettings.gamePath = openPanel.url!
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
                    FFXIVSettings.gamePath = openPanel.url!
                }
                openPanel.close()
            }
        }
    }
}

