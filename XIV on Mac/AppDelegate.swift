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
	@IBOutlet private var fpsButton: NSMenuItem!
	@IBOutlet private var fullButton: NSMenuItem!
	@IBOutlet private var frametimeButton: NSMenuItem!
	@IBOutlet private var fps30Button: NSMenuItem!
	@IBOutlet private var fps60Button: NSMenuItem!
	@IBOutlet private var fps120Button: NSMenuItem!
	@IBOutlet private var fpsUncappedButton: NSMenuItem!
	
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
	
	@IBAction func fpsHud(_ sender: Any) {
		Util.launchWine(args: ["reg", "add", "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment", "/v", "dxvk_hud", "/d", "fps", "/f"])
		fpsButton.state = .on
		fullButton.state = .off
		frametimeButton.state = .off
		
	}
	
	@IBAction func fullHud(_ sender: Any) {
		Util.launchWine(args: ["reg", "add", "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment", "/v", "dxvk_hud", "/d", "full", "/f"])
		fullButton.state = .on
		fpsButton.state = .off
		frametimeButton.state = .off
	}
	
	
	@IBAction func frametimesHud(_ sender: Any) {
		Util.launchWine(args: ["reg", "add", "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment", "/v", "dxvk_hud", "/d", "frametimes", "/f"])
		fpsButton.state = .off
		fullButton.state = .off
		frametimeButton.state = .on
		
	}

	@IBAction func fps30(_ sender: Any) {
		Util.launchWine(args: ["reg", "add", "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment", "/v", "DXVK_FRAME_RATE", "/d", "30", "/f"])
		fps30Button.state = .on
		fps60Button.state = .off
		fps120Button.state = .off
		fpsUncappedButton.state = .off
		
	}
	
	@IBAction func fps60(_ sender: Any) {
		Util.launchWine(args: ["reg", "add", "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment", "/v", "DXVK_FRAME_RATE", "/d", "60", "/f"])
		fps30Button.state = .off
		fps60Button.state = .on
		fps120Button.state = .off
		fpsUncappedButton.state = .off
		
	}
	
	@IBAction func fps120(_ sender: Any) {
		Util.launchWine(args: ["reg", "add", "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment", "/v", "DXVK_FRAME_RATE", "/d", "120", "/f"])
		fps30Button.state = .off
		fps60Button.state = .off
		fps120Button.state = .on
		fpsUncappedButton.state = .off
		
	}
	
	@IBAction func fpsUncapped(_ sender: Any) {
		Util.launchWine(args: ["reg", "add", "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment", "/v", "DXVK_FRAME_RATE", "/d", "0", "/f"])
		fps30Button.state = .off
		fps60Button.state = .off
		fps120Button.state = .off
		fpsUncappedButton.state = .on
		
	}
	
	
}

