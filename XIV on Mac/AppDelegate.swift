//
//  AppDelegate.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    var launchWinController: NSWindowController?
    var settingsWinController: NSWindowController?
    var installerWinController: NSWindowController?

    @IBOutlet private var macButton: NSMenuItem!
    @IBOutlet private var winButton: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        launchWinController = storyboard.instantiateController(withIdentifier: "LaunchWindow") as? NSWindowController
        settingsWinController = storyboard.instantiateController(withIdentifier: "SettingsWindow") as? NSWindowController
        installerWinController = storyboard.instantiateController(withIdentifier: "InstallerWindow") as? NSWindowController
        Util.make(dir: Wine.prefix.path)
        Util.make(dir: Wine.xomData.path)
        Util.make(dir: Util.cache.path)
        if Util.macLicense {
            macLicense()
        }
        else {
            winLicense()
        }
        SocialIntegration.discord.setPresence()
        if FileManager.default.fileExists(atPath: Util.launchPath) {
            launchWinController?.showWindow(self)
        }
        else {
            installerWinController?.showWindow(self)
        }
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
    
    func relaunch() {
        let alert = NSAlert()
        alert.messageText = "Do you want to restart XIV on Mac?"
        alert.informativeText = "An application restart is required in order to change the license configuration"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            let task = Process()
            task.launchPath = "/bin/sh"
            task.arguments = ["-c", "sleep 5; open \"\(Bundle.main.bundlePath)\""]
            task.launch()
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    @IBAction func winLicense(_ sender: Any) {
        winLicense()
        relaunch()
    }
    
    func winLicense() {
        macButton.state = .off
        winButton.state = .on
        DispatchQueue.global(qos: .utility).async {
            Util.macLicense = false
        }
    }
	
    @IBAction func macLicense(_ sender: Any) {
        macLicense()
        relaunch()
    }
    
    func macLicense() {
        macButton.state = .on
        winButton.state = .off
        DispatchQueue.global(qos: .utility).async {
            Util.macLicense = true
        }
    }
    
    @IBAction func play(_ sender: Any) {
        Util.launchExec(terminating: false)
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
        if #available(OSX 11.0, *) {
            Util.launch(exec: URL(string: "file:///usr/bin/open")!,
                        args: ["-n", "-b", "com.apple.Terminal",
                               Bundle.main.url(forResource: "install_gshade", withExtension: "sh", subdirectory: "GShade")!.path,
                               "--env", "WINEPATH=\( Bundle.main.url(forResource: "bin", withExtension: nil, subdirectory: "wine")!.path)",
                               "--env", "WINEESYNC=\(Wine.esync ? "1" : "0")",
                               "--env", "WINEPREFIX=\(Wine.prefix.path)"])
        } else {
            let alert = NSAlert()
            alert.messageText = "Catalina is not supported by the automatic GShade installer"
            alert.informativeText = "You can still manually run the GShade Linux install script"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    @IBAction func manualGShade(_ sender: Any) {
        if #available(OSX 11.0, *) {
            Util.launch(exec: URL(string: "file:///usr/bin/open")!,
                        args: ["-n", "-b", "com.apple.Terminal",
                               Bundle.main.url(forResource: "manual_gshade", withExtension: "sh", subdirectory: "GShade")!.path,
                               "--env", "WINEPATH=\( Bundle.main.url(forResource: "bin", withExtension: nil, subdirectory: "wine")!.path)",
                               "--env", "WINEESYNC=\(Wine.esync ? "1" : "0")",
                               "--env", "WINEPREFIX=\(Wine.prefix.path)"])
        } else {
            let alert = NSAlert()
            alert.messageText = "When running Catalina you must have wine or CrossOver installed"
            alert.informativeText = "You can also manually add the wine version bundled with the XIV on Mac.app to your $PATH"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
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
	
    @IBAction func selectExec(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose the executable to start on App launch"
        if #available(macOS 11.0, *) {
            openPanel.subtitle = "It should end on .exe"
        }
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = true
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.begin() { (response) in
            if response == .OK {
                openPanel.close()
                Util.launchPath = openPanel.url!.path
            }
        }
    }
}

