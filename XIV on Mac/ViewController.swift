//
//  ViewController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa

class XIVController: NSViewController {
    
    @IBOutlet private var status: NSTextField!
    @IBOutlet private var info: NSTextField!
    @IBOutlet private var button: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupObservers()
        if !FileManager.default.fileExists(atPath: Util.localSettings + "XIVLauncher") {
            button.isHidden = true
            DispatchQueue.global(qos: .userInitiated).async {
                Setup.downloadDeps()
            }
        }
        else {
            self.status.stringValue = "Click Play to start the game"
            self.info.stringValue = ""
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if !button.isHidden {
            self.view.window?.title = "XIV on Mac"
        }
    }
    
    @objc
    func downloadDone(_ notif: Notification) {
        Setup.installDeps()
    }
    
    @objc
    func depsDone(_ notif: Notification) {
        DispatchQueue.main.async {
            self.button.isHidden = false
            self.view.window?.title = "XIV on Mac"
            self.status.stringValue = "Click Play to start the game"
            self.info.stringValue = ""
        }
    }
    
    @objc
    func updateStatus(_ notif: Notification) {
        let header = notif.userInfo?[Notification.status.header]! as! String
        let info = notif.userInfo?[Notification.status.info]! as! String
        DispatchQueue.main.async {
            self.button.isHidden = true
            self.status.stringValue = header
            self.info.stringValue = info
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
    
    @IBAction func dvkSettings(_ sender: Any) {
        let settingsWinController = self.storyboard!.instantiateController(withIdentifier: "SettingsWindow") as! NSWindowController
        settingsWinController.showWindow(self)
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self,selector: #selector(downloadDone(_:)),name: .depDownloadDone, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(depsDone(_:)),name: .depInstallDone, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(updateStatus(_:)),name: .installStatusUpdate, object: nil)
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
