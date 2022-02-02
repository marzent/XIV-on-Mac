//
//  ViewController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa

class InstallerController: NSViewController {
    
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
        Setup.vanilla = (sender.identifier == NSUserInterfaceItemIdentifier("vanilla_launcher"))
    }
    
    @IBAction func gameFileSelect(_ sender: NSButton) {
        switch sender.identifier! {
        case NSUserInterfaceItemIdentifier("copy_game"):
            Setup.copy = true
            Setup.link = false
        case NSUserInterfaceItemIdentifier("link_game"):
            Setup.copy = false
            Setup.link = true
        default:
            Setup.copy = false
            Setup.link = false
        }
    }
    
    @IBAction func startInstall(_ sender: Any) {
        Task {
            do {
                if Setup.copy || Setup.link {
                    if let gamePath = await getGameDirectory() {
                        install(gamePath: gamePath)
                        tabView.selectNextTabViewItem(sender)
                    }
                }
                else {
                    install()
                    tabView.selectNextTabViewItem(sender)
                }
            }
        }
    }
    
    private func getGameDirectory() async -> String? {
        let appSupportFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last!
        let gamePaths = [appSupportFolder.appendingPathComponent("FINAL FANTASY XIV ONLINE/Bottles/published_Final_Fantasy/drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn").path,
                         appSupportFolder.appendingPathComponent("CrossOver/Bottles/Final Fantasy XIV Online/drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn").path]
        for gamePath in gamePaths {
            if isValidGameDirectory(gamePath: gamePath) {
                let alertTask = Task { () -> Bool in
                    do {
                        let alert = NSAlert()
                        alert.messageText = "FINAL FANTASY XIV ONLINE install found!"
                        alert.informativeText = "Would you like to use the install located at \(gamePath)?"
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: "Yes")
                        alert.addButton(withTitle: "No")
                        let result = await alert.beginSheetModal(for: self.view.window!)
                        return result == .alertFirstButtonReturn
                    }
                }
                if try! await alertTask.result.get() {
                    return gamePath
                }
            }
        }
        let alertTask = Task { () -> Bool in
            do {
                let alert = NSAlert()
                alert.messageText = "No FINAL FANTASY XIV ONLINE installs were detected..."
                alert.informativeText = "Would you like to manually choose a Folder?"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Yes")
                alert.addButton(withTitle: "No")
                let result = await alert.beginSheetModal(for: self.view.window!)
                return result == .alertFirstButtonReturn
            }
        }
        if try! await alertTask.result.get() {
            let openTask = Task { () -> String? in
                let openPanel = NSOpenPanel()
                openPanel.title = "Choose the folder with the existing install"
                if #available(macOS 11.0, *) {
                    openPanel.subtitle = "It should contain the folders \"game\" and \"boot\" and the game executable."
                }
                openPanel.showsResizeIndicator = true
                openPanel.showsHiddenFiles = true
                openPanel.canChooseDirectories = true
                openPanel.canChooseFiles = false
                openPanel.canCreateDirectories = false
                openPanel.allowsMultipleSelection = false
                let result = await openPanel.beginSheetModal(for: view.window!)
                openPanel.close()
                if result != .OK {
                    return nil
                }
                let openPath = openPanel.url!.path
                if (self.isValidGameDirectory(gamePath: openPath)) {
                    return openPath
                }
                let alert = NSAlert()
                alert.messageText = "Invalid FFXIV Directory"
                alert.informativeText = "It should contain the folders \"game\" and \"boot\" and the game executable and not be located inside the XIV on Mac wine prefix."
                alert.alertStyle = .critical
                alert.addButton(withTitle: "By the Twelve!")
                await alert.beginSheetModal(for: self.view.window!)
                return nil
            }
            if let gamePath = try! await openTask.result.get() {
                return gamePath
            }
        }
        return nil
    }
    
    private func isValidGameDirectory(gamePath: String) -> Bool {
        let game = gamePath + "/game/ffxiv_dx11.exe" //needed in order to discriminate against SE's app bundle version
        let boot = gamePath + "/boot"
        let validGame = FileManager.default.fileExists(atPath: game)
        let validBoot = FileManager.default.fileExists(atPath: boot)
        let components = gamePath.split(separator: "/")
        let trimmedComponents = components[...min(components.count - 1, 5)]
        if "/" + trimmedComponents.map(String.init).joined(separator: "/") == Wine.prefix.path {
            return false // do not allow game directories from the prefix itself
        }
        return (validGame && validBoot)
    }
    
    func install(gamePath: String = "") {
        Setup.gamePath = gamePath
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(name: .depInstall, object: nil)
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
        Setup.observers()
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
