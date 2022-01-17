//
//  AppDelegate.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let licenseSettingKey = "LicenseType"
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    var settingsWinController: NSWindowController?
    var installerWinController: NSWindowController?

    @IBOutlet private var macButton: NSMenuItem!
    @IBOutlet private var winButton: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        settingsWinController = storyboard.instantiateController(withIdentifier: "SettingsWindow") as? NSWindowController
        installerWinController = storyboard.instantiateController(withIdentifier: "InstallerWindow") as? NSWindowController
        Util.make(dir: Util.prefix.path)
        Util.make(dir: Util.cache.path)
        if Util.getSetting(settingKey: licenseSettingKey, defaultValue: "Mac") == "Mac" {
            macLicense()
        }
        else {
            winLicense()
        }
        SocialIntegration.discord.setPresence()
        if FileManager.default.fileExists(atPath: Util.launchPath) {
            Util.launchWine(args: ["wineboot", "-u"], blocking: true)
            Util.launchGame()
        }
        else {
            installerWinController?.showWindow(self)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        Util.killWine()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
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
        Util.launchWine(args: ["reg", "add", "HKEY_CURRENT_USER\\Software\\Wine", "/v", "HideWineExports", "/d", "1", "/f"])
        macButton.state = .off
        winButton.state = .on
        UserDefaults.standard.set("Win", forKey: licenseSettingKey)
    }
	
    @IBAction func macLicense(_ sender: Any) {
        macLicense()
        relaunch()
    }
    
    func macLicense() {
        Util.launchWine(args: ["reg", "add", "HKEY_CURRENT_USER\\Software\\Wine", "/v", "HideWineExports", "/d", "0", "/f"])
        macButton.state = .on
        winButton.state = .off
        UserDefaults.standard.set("Mac", forKey: licenseSettingKey)
    }
    
    @IBAction func play(_ sender: Any) {
        Util.launchGame()
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
        Util.launch(exec: URL(string: "file:///usr/bin/open")!,
                    args: ["-n", "-b", "com.apple.Terminal",
                           Bundle.main.url(forResource: "install_gshade", withExtension: "sh", subdirectory: "")!.path,
                           "--env", "WINEPATH=\( Bundle.main.url(forResource: "bin", withExtension: nil, subdirectory: "wine")!.path)",
                           "--env", "WINEESYNC=\(Util.esync ? "1" : "0")",
                           "--env", "WINEPREFIX=\(Util.prefix.path)"])
    }
    
    @IBAction func fullInstall(_ sender: Any) {
        installerWinController?.showWindow(self)
    }
    
    @IBAction func regedit(_ sender: Any) {
        Util.launchWine(args: ["regedit"])
    }
    
    @IBAction func winecfg(_ sender: Any) {
        Util.launchWine(args: ["winecfg"])
    }
    
    @IBAction func explorer(_ sender: Any) {
        Util.launchWine(args: ["explorer"])
    }
    
    @IBAction func cmd(_ sender: Any) {
        Util.launchWine(args: ["cmd"]) //fixme
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

