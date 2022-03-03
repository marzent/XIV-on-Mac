//
//  ViewController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa
import ZIPFoundation

class InstallerController: NSViewController {
    
    private enum GameFiles {
        case download
        case copy
        case point
    }
    
    private var action = GameFiles.download
    
    @IBOutlet private var status: NSTextField!
    @IBOutlet private var info: NSTextField!
    @IBOutlet private var tabView: NSTabView!
    @IBOutlet private var bar: NSProgressIndicator!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        bar.usesThreadedAnimation = true
    }
    
    @IBAction func nextTab(_ sender: Any) {
        tabView.selectNextTabViewItem(sender)
    }
    
    @IBAction func previousTab(_ sender: Any) {
        tabView.selectPreviousTabViewItem(sender)
    }
    
    @IBAction func versionSelect(_ sender: NSButton) {
        FFXIVSettings.dalamud = (sender.identifier == NSUserInterfaceItemIdentifier("withDalamud"))
    }
    
    @IBAction func licenseSelect(_ sender: NSButton) {
        switch sender.identifier! {
        case NSUserInterfaceItemIdentifier("windowsLicense"):
            DispatchQueue.global(qos: .utility).async {
                FFXIVSettings.platform = .windows
            }
        case NSUserInterfaceItemIdentifier("steamLicense"):
            DispatchQueue.global(qos: .utility).async {
                FFXIVSettings.platform = .steam
            }
        default:
            DispatchQueue.global(qos: .utility).async {
                FFXIVSettings.platform = .mac
            }
        }
    }
    
    @IBAction func gameFileSelect(_ sender: NSButton) {
        switch sender.identifier! {
        case NSUserInterfaceItemIdentifier("copyGame"):
            action = GameFiles.copy
        case NSUserInterfaceItemIdentifier("pointGame"):
            action = GameFiles.point
        default:
            action = GameFiles.download
        }
    }
    
    @IBAction func startInstall(_ sender: Any) {
        Task {
            switch(action) {
            case .download:
                tabView.selectNextTabViewItem(sender)
                install()
            case .copy:
                if let gamePath = await getGameDirectory() {
                    copyGame(gamePath: gamePath)
                    tabView.selectNextTabViewItem(sender)
                    install()
                }
            case .point:
                if let gamePath = await getGameDirectory() {
                    FFXIVSettings.gamePath = URL(fileURLWithPath: gamePath)
                    tabView.selectNextTabViewItem(sender)
                    install()
                }
            }
        }
    }
    
    private func copyGame(gamePath: String) {
        FFXIVSettings.gamePath = FFXIVSettings.defaultGameLoc
        Util.make(dir: FFXIVSettings.defaultGameLoc.deletingLastPathComponent().path)
        do {
            try FileManager.default.copyItem(atPath: gamePath, toPath: FFXIVSettings.defaultGameLoc.path)
        }
        catch {
            print("error copying game from \(gamePath)\n", to: &Util.logger)
        }
    }
    
    private func getGameDirectory() async -> String? {
        let appSupportFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last!
        let gamePaths = [appSupportFolder.appendingPathComponent("FINAL FANTASY XIV ONLINE/Bottles/published_Final_Fantasy/drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn").path,
                         appSupportFolder.appendingPathComponent("CrossOver/Bottles/Final Fantasy XIV Online/drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn").path]
        for gamePath in gamePaths {
            if InstallerController.isValidGameDirectory(gamePath: gamePath) {
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
                if (InstallerController.isValidGameDirectory(gamePath: openPath)) {
                    return openPath
                }
                let alert = NSAlert()
                alert.messageText = "Invalid FFXIV Directory"
                alert.informativeText = "It should contain the folders \"game\" and \"boot\" and the game executable."
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
    
    static func isValidGameDirectory(gamePath: String) -> Bool {
        let game = gamePath + "/game/ffxiv_dx11.exe" //needed in order to discriminate against SE's app bundle version
        let boot = gamePath + "/boot"
        let validGame = FileManager.default.fileExists(atPath: game)
        let validBoot = FileManager.default.fileExists(atPath: boot)
        return (validGame && validBoot)
    }
    
    func install() {
        DispatchQueue.global(qos: .userInitiated).async {
            let version = "1.0.5"
            let url = URL(string: "https://mac-dl.ffxiv.com/cw/finalfantasyxiv-\(version).zip")!
            var observation: NSKeyValueObservation?
            let downloadDone = DispatchGroup()
            downloadDone.enter()
            let task = FileDownloader.loadFileAsync(url: url) { response in
                downloadDone.leave()
            }
            if let task = task {
                observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                    DispatchQueue.main.async {
                        self.bar.doubleValue = self.bar.maxValue * progress.fractionCompleted
                    }
                }
                task.resume()
            }
            downloadDone.wait()
            observation?.invalidate()
            DispatchQueue.main.async {
                self.info.stringValue = "Extracting"
            }
            guard let archive = Archive(url: Util.cache.appendingPathComponent("finalfantasyxiv-\(version).zip"), accessMode: .read) else  {
                print("Fatal error reading base game archive\n", to: &Util.logger)
                return
            }
            let baseGamePath = "FINAL FANTASY XIV ONLINE.app/Contents/SharedSupport/finalfantasyxiv/support/published_Final_Fantasy/drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn/"
            let baseGameFiles = archive.filter({ $0.path.starts(with: baseGamePath) })
            Util.make(dir: FFXIVSettings.gamePath.deletingLastPathComponent())
            DispatchQueue.main.async {
                self.bar.doubleValue = 0.0
            }
            for (i, file) in baseGameFiles.enumerated() {
                let components = URL(fileURLWithPath: file.path).pathComponents
                let relDestination = components[10...].joined(separator: "/")
                let destination = URL(fileURLWithPath: relDestination, relativeTo: FFXIVSettings.gamePath.deletingLastPathComponent())
                Util.make(dir: destination.deletingLastPathComponent())
                try? _ = archive.extract(file, to: destination)
                DispatchQueue.main.async {
                    self.bar.doubleValue = self.bar.maxValue * Double(i + 1) / Double(baseGameFiles.count)
                }
            }
            DXVK.install()
            InstallerController.vanillaConf()
            DispatchQueue.main.async {
                self.tabView.selectNextTabViewItem(self)
            }
        }
    }
    
    private static func vanillaConf() {
        let fm = FileManager.default
        let content = "<FINAL FANTASY XIV Boot Config File>\n\n<Version>\nBrowser 1\nStartupCompleted 1"
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("My Games/FINAL FANTASY XIV - A Realm Reborn")
        Util.make(dir: folder)
        let file = folder.appendingPathComponent("FFXIV_BOOT.cfg")
        do {
            if fm.fileExists(atPath: file.path) {
                try fm.removeItem(atPath: file.path)
            }
            try content.write(to: file, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Error writing ffxiv boot launcher config file\n", to: &Util.logger)
        }
    }
    
    @IBAction func cancelInstall(_ sender: Any) {
        Util.quit()
    }

    @IBAction func openFAQ(_ sender: Any) {
        let url = URL(string: "https://www.xivmac.com/xiv-mac-application-help")!
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func closeWindow(_ sender: Any) {
        self.view.window?.close()
        self.tabView.selectTabViewItem(at: 0)
        NotificationCenter.default.post(name: .installDone, object: nil)
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
