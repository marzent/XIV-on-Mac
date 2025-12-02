//
//  ViewController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa
import SeeURL

class InstallerController: NSViewController {
    private enum GameFiles {
        case download
        case copy
        case point
    }

    private var action = GameFiles.point

    @IBOutlet private var status: NSTextField!
    @IBOutlet private var info: NSTextField!
    @IBOutlet private var tabView: NSTabView!

    @IBAction func nextTab(_ sender: Any) {
        tabView.selectNextTabViewItem(sender)
    }

    @IBAction func previousTab(_ sender: Any) {
        tabView.selectPreviousTabViewItem(sender)
    }

    @IBAction func versionSelect(_ sender: NSButton) {
        // TEMPORARILY DISABLED: Dalamud installation option
        // To re-enable: Uncomment the block below
        /*
        Settings.dalamudEnabled =
            (sender.identifier == NSUserInterfaceItemIdentifier("withDalamud"))
        */
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
            case .copy:
                if let gamePath = await getGameDirectory() {
                    copyGame(gamePath: gamePath)
                    tabView.selectNextTabViewItem(sender)
                }
            case .point:
                if let gamePath = await getGameDirectory() {
                    Settings.gamePath = URL(fileURLWithPath: gamePath)
                    tabView.selectNextTabViewItem(sender)
                }
            }
        }
    }

    private func copyGame(gamePath: String) {
        Settings.gamePath = Settings.defaultGameLoc
        Util.make(dir: Settings.defaultGameLoc.deletingLastPathComponent().path)
        do {
            try FileManager.default.copyItem(
                atPath: gamePath, toPath: Settings.defaultGameLoc.path)
        } catch {
            Log.error("Error copying game from \(gamePath)")
        }
    }

    private func getGameDirectory() async -> String? {
        let appSupportFolder = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).last!
        let gamePaths = [
            appSupportFolder.appendingPathComponent(
                "FINAL FANTASY XIV ONLINE/Bottles/published_Final_Fantasy/drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn"
            ).path,
            appSupportFolder.appendingPathComponent(
                "CrossOver/Bottles/Final Fantasy XIV Online/drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn"
            ).path,
        ]
        for gamePath in gamePaths {
            if InstallerController.isValidGameDirectory(gamePath: gamePath) {
                let alertTask = Task { () -> Bool in
                    do {
                        let alert = NSAlert()
                        alert.messageText = NSLocalizedString(
                            "INSTALLER_FOUND_MESSAGE", comment: "")
                        alert.informativeText = String(
                            format: NSLocalizedString(
                                "INSTALLER_FOUND_INFORMATIVE", comment: ""),
                            gamePath)
                        alert.alertStyle = .informational
                        alert.addButton(
                            withTitle: NSLocalizedString(
                                "BUTTON_YES", comment: ""))
                        alert.addButton(
                            withTitle: NSLocalizedString(
                                "BUTTON_NO", comment: ""))
                        let result = await alert.beginSheetModal(
                            for: self.view.window!)
                        return result == .alertFirstButtonReturn
                    }
                }
                if await alertTask.result.get() {
                    return gamePath
                }
            }
        }
        let alertTask = Task { () -> Bool in
            do {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString(
                    "INSTALLER_NOT_DETECTED_MESSAGE", comment: "")
                alert.informativeText = NSLocalizedString(
                    "INSTALLER_NOT_DETECTED_INFORMATIVE", comment: "")
                alert.alertStyle = .warning
                alert.addButton(
                    withTitle: NSLocalizedString("BUTTON_YES", comment: ""))
                alert.addButton(
                    withTitle: NSLocalizedString("BUTTON_NO", comment: ""))
                let result = await alert.beginSheetModal(for: self.view.window!)
                return result == .alertFirstButtonReturn
            }
        }
        if await alertTask.result.get() {
            let openTask = Task { () -> String? in
                let openPanel = NSOpenPanel()
                openPanel.title = NSLocalizedString(
                    "INSTALLER_PATH_TITLE", comment: "")
                openPanel.subtitle = NSLocalizedString(
                    "INSTALLER_PATH_SUBTITLE", comment: "")
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
                if InstallerController.isValidGameDirectory(gamePath: openPath)
                {
                    return openPath
                }
                let alert = NSAlert()
                alert.messageText = NSLocalizedString(
                    "INSTALLER_PATH_INVALID_MESSAGE", comment: "")
                alert.informativeText = NSLocalizedString(
                    "INSTALLER_PATH_INVALID_INFORMATIVE", comment: "")
                alert.alertStyle = .critical
                alert.addButton(
                    withTitle: NSLocalizedString(
                        "INSTALLER_PATH_INVALID_BUTTON", comment: ""))
                await alert.beginSheetModal(for: self.view.window!)
                return nil
            }
            if let gamePath = await openTask.result.get() {
                return gamePath
            }
        }
        return nil
    }

    static func isValidGameDirectory(gamePath: String) -> Bool {
        let game = gamePath + "/game/ffxiv_dx11.exe"  // needed in order to discriminate against SE's app bundle version
        let boot = gamePath + "/boot"
        let validGame = FileManager.default.fileExists(atPath: game)
        let validBoot = FileManager.default.fileExists(atPath: boot)
        return (validGame && validBoot)
    }

    @IBAction func cancelInstall(_ sender: Any) {
        Util.quit()
    }

    @IBAction func openFAQ(_ sender: Any) {
        let url = URL(
            string: "https://www.xivmac.com/xiv-mac-application-help")!
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
