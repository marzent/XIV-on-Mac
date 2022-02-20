//
//  AppDelegate.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa
import Sparkle

@main class AppDelegate: NSObject, NSApplicationDelegate {
    
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    var settingsWinController: NSWindowController?
    var installerWinController: NSWindowController?

    @IBOutlet private var sparkle: SPUStandardUpdaterController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        sparkle.updater.checkForUpdatesInBackground()
        settingsWinController = storyboard.instantiateController(withIdentifier: "SettingsWindow") as? NSWindowController
        installerWinController = storyboard.instantiateController(withIdentifier: "InstallerWindow") as? NSWindowController
        Util.make(dir: Wine.xomData.path)
        Util.make(dir: Util.cache.path)
        SocialIntegration.discord.setPresence()
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
    
    @IBAction func installDXVK(_ sender: Any) {
        Setup.DXVK()
    }
    
    @IBAction func installMSVC32(_ sender: Any) {
        Setup.installMSVC32()
    }
    
    @IBAction func installMSVC64(_ sender: Any) {
        Setup.installMSVC64()
    }
    
    @IBAction func installDotNet40(_ sender: Any) {
        Setup.installDotNet40()
    }
    
    @IBAction func installDotNet462(_ sender: Any) {
        Setup.installDotNet462()
    }
    
    @IBAction func installDotNet472(_ sender: Any) {
        Setup.installDotNet472()
    }
    
    @IBAction func installDotNet48(_ sender: Any) {
        Setup.installDotNet48()
    }
    
    @IBAction func installDotNet(_ sender: Any) {
        Setup.installDotNet40()
        Setup.installDotNet462()
        Setup.installDotNet472()
        Setup.installDotNet48()
    }
    
    @IBAction func installXL(_ sender: Any) {
        Setup.XLConf()
        Setup.XL()
    }
    
    @IBAction func vanillaLauncher(_ sender: Any) {
        Setup.vanillaConf()
        Setup.vanillaLauncher()
    }
    
    @IBAction func movieFix(_ sender: Any) {
        Setup.movieFix()
    }
    
    @IBAction func installGShade(_ sender: Any) {
        GShade.install()
    }
    
    @IBAction func manualGShade(_ sender: Any) {
        GShade.manual()
    }
    
    @IBAction func fullInstall(_ sender: Any) {
        installerWinController?.showWindow(self)
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

