//
//  ViewController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa

class InstallerController: NSViewController {
    
    private var vanillaClient = true
    private var copyGame = false
    private var linkGame = false
    
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
        vanillaClient = (sender.identifier == NSUserInterfaceItemIdentifier("vanilla_launcher"))
    }
    
    @IBAction func gameFileSelect(_ sender: NSButton) {
        switch sender.identifier! {
        case NSUserInterfaceItemIdentifier("copy_game"):
            copyGame = true
            linkGame = false
        case NSUserInterfaceItemIdentifier("link_game"):
            copyGame = false
            linkGame = true
        default:
            copyGame = false
            linkGame = false
        }
    }
    
    @IBAction func startInstall(_ sender: Any) {
        if copyGame || linkGame {
            let openPanel = NSOpenPanel()
            openPanel.title = "Choose the folder with the existing install"
            if #available(macOS 11.0, *) {
                openPanel.subtitle = "It should contain the folders \"game\" and \"boot\"."
            }
            openPanel.showsResizeIndicator = true
            openPanel.showsHiddenFiles = true
            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles = false
            openPanel.canCreateDirectories = false
            openPanel.allowsMultipleSelection = false
            openPanel.beginSheetModal(for:self.view.window!) { (response) in
                if response == .OK {
                    openPanel.close()
                    if (!self.isValidGameDirectory(gamePath: openPanel.url!.path)) {
                        let alert = NSAlert()
                        alert.messageText = "Invalid FFXIV Directory"
                        alert.informativeText = "It should contain the folders \"game\" and \"boot\"."
                        alert.addButton(withTitle: "By the Twelve!")
                        alert.runModal()
                    } else {
                        self.tabView.selectNextTabViewItem(sender)
                        self.install(gamePath: openPanel.url!.path)
                    }
                }
            }
        }
        else {
            install()
            tabView.selectNextTabViewItem(sender)
        }
    }
    
    private func isValidGameDirectory(gamePath: String) -> Bool {
        let game = gamePath + "/game"
        let boot = gamePath + "/boot"
        let validGame = FileManager.default.fileExists(atPath: game)
        let validBoot = FileManager.default.fileExists(atPath: boot)
        return (validGame && validBoot)
    }
    
    func install(gamePath: String = "") {
        DispatchQueue.global(qos: .default).async {
            Setup.install(vanilla: self.vanillaClient, copy: self.copyGame, link: self.linkGame, gamePath: gamePath)
        }
    }
    
    @IBAction func cancelInstall(_ sender: Any) {
        DispatchQueue.main.async {
            NSApplication.shared.terminate(sender)
        }
    }

    @IBAction func openFAQ(_ sender: Any) {
        let url = URL(string: "https://www.xivmac.com/xiv-mac-application-help")!
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
