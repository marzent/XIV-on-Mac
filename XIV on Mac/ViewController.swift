//
//  ViewController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa

class XIVController: NSViewController {
    
    @IBOutlet private var status: NSTextField!
    @IBOutlet private var button: NSButton!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        NotificationCenter.default.addObserver(self,selector: #selector(downloadDone(_:)),name: .depDownloadDone, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(depsDone(_:)),name: .depInstallDone, object: nil)
        if !FileManager.default.fileExists(atPath: Util.localSettings + "XIVLauncher") {
            button.isHidden = true
            DispatchQueue.main.async {
                Setup.downloadDeps()
            }
        }
        else {
            self.view.window?.title = "XIV on Mac"
            self.status.stringValue = "Click Play to start the game"
        }
    }
    
    @objc
    func downloadDone(_ notif: Notification) {
        DispatchQueue.main.async {
            self.status.stringValue = "Installing dependencies...."
            Setup.installDeps()
        }
    }
    
    @objc
    func depsDone(_ notif: Notification) {
        DispatchQueue.main.async {
            self.button.isHidden = false
            self.view.window?.title = "XIV on Mac"
            self.status.stringValue = "Click Play to start the game"
        }
    }
    
    @IBAction func play(_ sender: Any) {
        Util.launchXL()
        NSApp.hide(nil)
    }
    
    @IBAction func installDeps(_ sender: Any) {
        Setup.downloadDeps()
    }
    
    @IBAction func installDXVK(_ sender: Any) {
        Setup.DXVK()
    }
    
    @IBAction func installXL(_ sender: Any) {
        Setup.XL()
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
    
	@IBAction func fps(_ sender: Any) {
		Util.launchWine(args: ["reg", "add", "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment", "/v", "dxvk_hud", "/d", "fps", "/f"])
	}
	
	@IBAction func full(_sender: Any) {
		Util.launchWine(args: ["reg", "add", "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment", "/v", "dxvk_hud", "/d", "full", "/f"])
	}
	@IBAction func frametimes(_sender: Any) {
		Util.launchWine(args: ["reg", "add", "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment", "/v", "dxvk_hud", "/d", "frametimes", "/f"])
	}
	
	@IBAction func fps30(_ sender: Any) {
		Util.launchWine(args: ["reg", "add", "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment", "/v", "DXVK_FRAME_RATE", "/d", "30", "/f"])
	}
	
	@IBAction func fps60(_sender: Any) {
		Util.launchWine(args: ["reg", "add", "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment", "/v", "DXVK_FRAME_RATE", "/d", "60", "/f"])
	}
	@IBAction func fps120(_sender: Any) {
		Util.launchWine(args: ["reg", "add", "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment", "/v", "DXVK_FRAME_RATE", "/d", "120", "/f"])
	}
	
	@IBAction func fpsUncapped(_sender: Any) {
		Util.launchWine(args: ["reg", "add", "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment", "/v", "DXVK_FRAME_RATE", "/d", "0", "/f"])
	}

}

class XIVWindowController: NSWindowController, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.hide(nil)
        return false
    }
}

extension NSTextView {
    func append(string: String) {
        DispatchQueue.main.async {
            self.textStorage?.append(NSAttributedString(string: string))
            self.scrollToEndOfDocument(nil)
        }
    }
}
