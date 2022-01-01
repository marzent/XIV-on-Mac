//
//  ViewController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa

class InstallerController: NSViewController {
    
    private var vanillaClient = true
    
    @IBOutlet private var status: NSTextField!
    @IBOutlet private var info: NSTextField!
    @IBOutlet private var tabView: NSTabView!
    @IBOutlet private var spinner: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupObservers()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        spinner.usesThreadedAnimation = true
        spinner.startAnimation(self)
    }
    
    @objc
    func depsDone(_ notif: Notification) {
        DispatchQueue.main.async {
            self.tabView.selectNextTabViewItem(self)
        }
    }
    
    @objc
    func updateStatus(_ notif: Notification) {
        let header = notif.userInfo?[Notification.status.header]! as! String
        let info = notif.userInfo?[Notification.status.info]! as! String
        DispatchQueue.main.async {
            self.status.stringValue = header
            self.info.stringValue = info
        }
    }
    
    @IBAction func nextTab(_ sender: Any) {
        tabView.selectNextTabViewItem(sender)
    }
    
    @IBAction func previousTab(_ sender: Any) {
        tabView.selectPreviousTabViewItem(sender)
    }
    
    @IBAction func versionSelect(_ sender: NSButton) {
        vanillaClient = (sender.stringValue == "Square Enix Launcher")
    }
    
    @IBAction func gameFileSelect(_ sender: NSButton) {
        //todo
    }
    
    @IBAction func startInstall(_ sender: Any) {
        tabView.selectNextTabViewItem(sender)
        DispatchQueue.global(qos: .default).async {
            Setup.installDeps(vanilla: self.vanillaClient)
        }
    }
    
    @IBAction func cancelInstall(_ sender: Any) {
        DispatchQueue.main.async {
            NSApplication.shared.terminate(sender)
        }
    }

    @IBAction func openFAQ(_ sender: Any) {
        let url = URL(string: "https://www.xivmac.com/faq")!
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func closeWindow(_ sender: Any) {
        self.view.window?.close()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self,selector: #selector(depsDone(_:)),name: .depInstallDone, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(updateStatus(_:)),name: .installStatusUpdate, object: nil)
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
