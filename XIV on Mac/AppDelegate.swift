//
//  AppDelegate.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet private var macButton: NSMenuItem!
    @IBOutlet private var winButton: NSMenuItem!
	
    let licenseSettingKey = "LicenseType"

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Util.make(dir: Util.prefix.path)
        Util.make(dir: Util.cache.path)
        if Util.getSetting(settingKey: licenseSettingKey, defaultValue: "Mac") == "Mac" {
            macButton.state = .on
            winButton.state = .off
        }
        else {
            macButton.state = .off
            winButton.state = .on
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        Util.killWine(logger: nil)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    @IBAction func winLicense(_ sender: Any) {
        Util.launchWine(args: ["reg", "add", "HKEY_CURRENT_USER\\Software\\Wine", "/v", "HideWineExports", "/d", "1", "/f"])
        macButton.state = .off
        winButton.state = .on
        UserDefaults.standard.set("Win", forKey: licenseSettingKey)
    }
	
    @IBAction func macLicense(_ sender: Any) {
        Util.launchWine(args: ["reg", "add", "HKEY_CURRENT_USER\\Software\\Wine", "/v", "HideWineExports", "/d", "0", "/f"])
        macButton.state = .on
        winButton.state = .off
        UserDefaults.standard.set("Mac", forKey: licenseSettingKey)
    }
	
}

