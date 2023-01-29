//
//  ViewController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa
import SeeURL
import ZIPFoundation

class InstallerController: NSViewController, ObservableObject {
    public enum GameFiles {
        case download
        case copy
        case point
    }
    
    enum InstallerSheetPage: Int {
        case selectOption = 0
        case selectLicense
        case copyGame
        case installing
        case done
    }

    private var action = GameFiles.download
    
    @Published var installing: Bool = false
    @Published var status: String = ""
    @Published var info: String = ""
    @Published var progress: Double = 0.0
    @Published var progressMax: Double = 100.0
    @Published var page: InstallerSheetPage = .init(rawValue: 0)! // You can set this to another value to see that page in the SwiftUI preview without breaking the flow
    
    func presentInstaller() {
        DispatchQueue.main.async {
            self.page = .selectOption // Or should we do it by index 0 so the order it controlled by the enum?
            self.installing = true
        }
    }
    
    func previousPage() {
        DispatchQueue.main.async {
            if self.page.rawValue > 0 {
                self.page = InstallerSheetPage(rawValue: self.page.rawValue - 1) ?? .selectOption
            }
        }
    }
    
    func nextPage() {
        DispatchQueue.main.async {
            self.page = InstallerSheetPage(rawValue: self.page.rawValue + 1) ?? .done
        }
    }
    
    func startInstall(_ sender: Any) {
        Task {
            switch action {
            case .download:
                install()
            case .copy:
                if let gamePath = await getGameDirectory() {
                    copyGame(gamePath: gamePath)
                    install()
                }
            case .point:
                if let gamePath = await getGameDirectory() {
                    Settings.gamePath = URL(fileURLWithPath: gamePath)
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
        DispatchQueue.main.async { [self] in
            self.status = NSLocalizedString("INSTALLER_BASE_GAME", comment: "")
            self.info = NSLocalizedString("INSTALLER_DOWNLOADING", comment: "")
        }

        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let version = "1.0.8"
            let url = URL(string: "https://mac-dl.ffxiv.com/cw/finalfantasyxiv-\(version).zip")!
            do {
                try HTTPClient.fetchFile(url: url) { total, now, _ in
                    DispatchQueue.main.async { [self] in
                        progress = progressMax * (Double(now) / Double(total))
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
                info = NSLocalizedString("INSTALLER_EXTRACTING", comment: "")
            }
            guard let archive = Archive(url: Util.cache.appendingPathComponent("finalfantasyxiv-\(version).zip"), accessMode: .read) else {
                Log.fatal("Fatal error reading base game archive")
                return
            }
            let baseGamePath = "FINAL FANTASY XIV ONLINE.app/Contents/SharedSupport/finalfantasyxiv/support/published_Final_Fantasy/drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn/"
            let baseGameFiles = archive.filter { $0.path.starts(with: baseGamePath) }
            Util.make(dir: Settings.gamePath)
            DispatchQueue.main.async { [self] in
                progress = 0.0
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
                    progress = progressMax * Double(i + 1) / Double(baseGameFiles.count)
                }
            }
            InstallerController.vanillaConf()
            DispatchQueue.main.async {
                self.page = .done
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
    
    func cancelInstall(_ sender: Any) {
        Util.quit()
    }

    func openFAQ(_ sender: Any) {
        let url = URL(string: "https://www.xivmac.com/xiv-mac-application-help")!
        NSWorkspace.shared.open(url)
    }
    
    func closeWindow(_ sender: Any) {
        self.installing = false
        NotificationCenter.default.post(name: .installDone, object: nil)
    }
}
