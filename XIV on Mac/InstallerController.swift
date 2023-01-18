//
//  ViewController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa
import SeeURL
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
        Settings.dalamudEnabled = (sender.identifier == NSUserInterfaceItemIdentifier("withDalamud"))
    }
    
    @IBAction func licenseSelect(_ sender: NSButton) {
        switch sender.identifier! {
        case NSUserInterfaceItemIdentifier("windowsLicense"):
            DispatchQueue.global(qos: .utility).async {
                Settings.platform = .windows
            }
        case NSUserInterfaceItemIdentifier("steamLicense"):
            DispatchQueue.global(qos: .utility).async {
                Settings.platform = .steam
            }
        default:
            DispatchQueue.global(qos: .utility).async {
                Settings.platform = .mac
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
            switch action {
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
                    Settings.gamePath = URL(fileURLWithPath: gamePath)
                    tabView.selectNextTabViewItem(sender)
                    install()
                }
            }
        }
    }
    
    private func copyGame(gamePath: String) {
        Settings.gamePath = Settings.defaultGameLoc
        Util.make(dir: Settings.defaultGameLoc.deletingLastPathComponent().path)
        do {
            try FileManager.default.copyItem(atPath: gamePath, toPath: Settings.defaultGameLoc.path)
        }
        catch {
            Log.error("Error copying game from \(gamePath)")
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
                        alert.messageText = NSLocalizedString("INSTALLER_FOUND_MESSAGE", comment: "")
                        alert.informativeText = String(format: NSLocalizedString("INSTALLER_FOUND_INFORMATIVE", comment: ""), gamePath)
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: NSLocalizedString("BUTTON_YES", comment: ""))
                        alert.addButton(withTitle: NSLocalizedString("BUTTON_NO", comment: ""))
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
                alert.messageText = NSLocalizedString("INSTALLER_NOT_DETECTED_MESSAGE", comment: "")
                alert.informativeText = NSLocalizedString("INSTALLER_NOT_DETECTED_INFORMATIVE", comment: "")
                alert.alertStyle = .warning
                alert.addButton(withTitle: NSLocalizedString("BUTTON_YES", comment: ""))
                alert.addButton(withTitle: NSLocalizedString("BUTTON_NO", comment: ""))
                let result = await alert.beginSheetModal(for: self.view.window!)
                return result == .alertFirstButtonReturn
            }
        }
        if try! await alertTask.result.get() {
            let openTask = Task { () -> String? in
                let openPanel = NSOpenPanel()
                openPanel.title = NSLocalizedString("INSTALLER_PATH_TITLE", comment: "")
                if #available(macOS 11.0, *) {
                    openPanel.subtitle = NSLocalizedString("INSTALLER_PATH_SUBTITLE", comment: "")
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
                if InstallerController.isValidGameDirectory(gamePath: openPath) {
                    return openPath
                }
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("INSTALLER_PATH_INVALID_MESSAGE", comment: "")
                alert.informativeText = NSLocalizedString("INSTALLER_PATH_INVALID_INFORMATIVE", comment: "")
                alert.alertStyle = .critical
                alert.addButton(withTitle: NSLocalizedString("INSTALLER_PATH_INVALID_BUTTON", comment: ""))
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
        let game = gamePath + "/game/ffxiv_dx11.exe" // needed in order to discriminate against SE's app bundle version
        let boot = gamePath + "/boot"
        let validGame = FileManager.default.fileExists(atPath: game)
        let validBoot = FileManager.default.fileExists(atPath: boot)
        return (validGame && validBoot)
    }
    
    func install() {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let version = "1.0.8"
            let url = URL(string: "https://mac-dl.ffxiv.com/cw/finalfantasyxiv-\(version).zip")!
            do {
                try HTTPClient.fetchFile(url: url) { total, now, _ in
                    DispatchQueue.main.async { [self] in
                        bar.doubleValue = bar.maxValue * (Double(now) / Double(total))
                    }
                }
            }
            catch {
                DispatchQueue.main.sync {
                    let alert = NSAlert()
                    alert.addButton(withTitle: NSLocalizedString("BUTTON_CLOSE", comment: ""))
                    alert.alertStyle = .critical
                    alert.messageText = NSLocalizedString("INSTALLER_DOWNLOAD_ERROR_MESSAGE", comment: "")
                    alert.informativeText = NSLocalizedString("INSTALLER_DOWNLOAD_ERROR_INFORMATIVE", comment: "")
                    alert.runModal()
                    closeWindow(self)
                }
            }
            DispatchQueue.main.async { [self] in
                info.stringValue = NSLocalizedString("INSTALLER_EXTRACTING", comment: "")
            }
            guard let archive = Archive(url: Util.cache.appendingPathComponent("finalfantasyxiv-\(version).zip"), accessMode: .read) else {
                Log.fatal("Fatal error reading base game archive")
                return
            }
            let baseGamePath = "FINAL FANTASY XIV ONLINE.app/Contents/SharedSupport/finalfantasyxiv/support/published_Final_Fantasy/drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn/"
            let baseGameFiles = archive.filter { $0.path.starts(with: baseGamePath) }
            Util.make(dir: Settings.gamePath)
            DispatchQueue.main.async { [self] in
                bar.doubleValue = 0.0
            }
            for (i, file) in baseGameFiles.enumerated() {
                let components = URL(fileURLWithPath: file.path).pathComponents
                let relDestination = components[11...].joined(separator: "/")
                let destination = URL(fileURLWithPath: relDestination, relativeTo: Settings.gamePath)
                Util.removeBrokenSymlink(fileURL: destination)
                Util.make(dir: destination.deletingLastPathComponent())
                do {
                    try _ = archive.extract(file, to: destination)
                }
                catch {
                    Log.error("Installer: Failed to extract file \(destination.lastPathComponent) with error: \(error.localizedDescription)")
                }
                
                DispatchQueue.main.async { [self] in
                    bar.doubleValue = bar.maxValue * Double(i + 1) / Double(baseGameFiles.count)
                }
            }
            InstallerController.vanillaConf()
            DispatchQueue.main.async {
                self.tabView.selectNextTabViewItem(self)
            }
        }
    }
    
    private static func vanillaConf() {
        let fm = FileManager.default
        let content = "<FINAL FANTASY XIV Boot Config File>\n\n<Version>\nBrowser 1\nStartupCompleted 1"
        Util.make(dir: Settings.gameConfigPath)
        let file = Settings.gameConfigPath.appendingPathComponent("FFXIV_BOOT.cfg")
        do {
            if fm.fileExists(atPath: file.path) {
                try fm.removeItem(atPath: file.path)
            }
            try content.write(to: file, atomically: true, encoding: String.Encoding.utf8)
        }
        catch {
            Log.error("Error writing ffxiv boot launcher config file")
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
        view.window?.close()
        tabView.selectTabViewItem(at: 0)
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
