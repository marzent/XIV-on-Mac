//
//  FFXIVApp.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 17.03.22.
//

import Foundation

public struct FFXIVApp {
    static let configURL = Settings.gameConfigPath.appendingPathComponent(
        "FFXIV.cfg")
    static let seConfigURL = Util.userHome.appendingPathComponent(
        "/Documents/My Games/FINAL FANTASY XIV TC/",
        isDirectory: true)
    let bootRepoURL, bootExeURL, bootExe64URL, launcherExe64URL,
        updaterExe64URL: URL
    let gameRepoURL, dx9URL, dx11URL, sqpackFolderURL: URL
    private let bootFiles: [URL]

    init() {
        bootRepoURL = Settings.gamePath.appendingPathComponent("boot")
        bootExeURL = bootRepoURL.appendingPathComponent("ffxivboot.exe")
        bootExe64URL = bootRepoURL.appendingPathComponent("ffxivboot64.exe")
        launcherExe64URL = bootRepoURL.appendingPathComponent(
            "ffxivlauncher64.exe")
        updaterExe64URL = bootRepoURL.appendingPathComponent(
            "ffxivupdater64.exe")

        gameRepoURL = Settings.gamePath.appendingPathComponent("game")
        dx9URL = gameRepoURL.appendingPathComponent("ffxiv.exe")
        dx11URL = gameRepoURL.appendingPathComponent("ffxiv_dx11.exe")
        sqpackFolderURL = gameRepoURL.appendingPathComponent("sqpack")

        bootFiles = [
            bootExeURL, bootExe64URL, launcherExe64URL, updaterExe64URL,
        ]
    }

    static var running: Bool {
        instances > 0
    }

    static var instances: Int {
        Wine.pidsOf(processName: "ffxiv_dx11.exe").count
    }

    var installed: Bool {
        // bootFiles.allSatisfy { FileManager.default.fileExists(atPath: $0.path) }
        let bootExists = FileManager.default.fileExists(atPath: bootRepoURL.path)
        let gameExists = FileManager.default.fileExists(atPath: gameRepoURL.path)
        return bootExists && gameExists
    }

    private static func createConfigDirectory() {
        // Do we need to create the config directory itself?
        if !Util.pathExists(path: Settings.gameConfigPath) {
            Log.information("Cfg: Game Config path doesn't exist.")
            // Ok, so, it may be our first launch, or our prefix was wiped etc. However, there might be an existing install from either an older XOM or
            // the SE client. See if that cfg location exists.
            if Util.pathExists(path: seConfigURL) {
                Log.information("Cfg: Found existing game Cfg path to import.")
                // It does exist. Copy theirs to ours.
                do {
                    try FileManager.default.copyItem(
                        at: seConfigURL, to: Settings.gameConfigPath)
                } catch let createError as NSError {
                    Log.error(
                        "Cfg: Could not import existing Cfg: \(createError.localizedDescription)"
                    )
                }
            } else {
                Log.information("Cfg: No existing game Cfg found.")
                // SE version does not exist. Just create the directory.
                do {
                    try FileManager.default.createDirectory(
                        atPath: Settings.gameConfigPath.path,
                        withIntermediateDirectories: true, attributes: nil)
                } catch let createError as NSError {
                    Log.error(
                        "Cfg: Could not create Cfg directory: \(createError.localizedDescription)"
                    )
                }
            }
        }
    }

    /// Attempt to load the FFXIV.cfg file (raw contents) from disk. If it does not yet exist, we attempt to create it with default values, as well as its containing folders.
    ///  - Returns: The contents of the cfg file, or nil if it cannot be read and a default could not be created.
    static func loadCfgFile() -> String? {
        var configFileContents: String?
        if !Util.pathExists(path: FFXIVApp.configURL) {
            createConfigDirectory()
        }
        // One way or another we should have a config folder now. IF we copied the SE one, we might also now have a .cfg file. Check again.
        if !Util.pathExists(path: FFXIVApp.configURL) {
            // .cfg still doesn't exist, so let's copy in our Mac default one.
            Log.information(
                "Cfg: No existing game configuration, establishing Mac default settings."
            )
            do {
                let defaultCfgURL = Bundle.main.url(
                    forResource: "FFXIV-TcDefault", withExtension: "cfg")!
                try FileManager.default.copyItem(
                    at: defaultCfgURL, to: FFXIVApp.configURL)
            } catch let createError as NSError {
                Log.error(
                    "Cfg: Could not create default Mac settings: \(createError.localizedDescription)"
                )
            }
        }

        do {
            configFileContents = try String(contentsOf: FFXIVApp.configURL)
        } catch {
            Log.error(error.localizedDescription)
            return nil
        }
        return configFileContents
    }

    static func resetConfiguration() throws {
        let xomConfigBackupURL = FFXIVApp.configURL.deletingLastPathComponent()
            .appendingPathComponent("FFXIV.cfg.XOMBackup")
        if (try? xomConfigBackupURL.checkResourceIsReachable()) ?? false {
            // Delete any previous backup we may have made so that the copy will succeed
            try? FileManager.default.removeItem(at: xomConfigBackupURL)
        }
        try FileManager.default.copyItem(
            at: FFXIVApp.configURL, to: xomConfigBackupURL)
        try FileManager.default.removeItem(at: FFXIVApp.configURL)
        let defaultCfgURL = Bundle.main.url(
            forResource: "FFXIV-TcDefault", withExtension: "cfg")!
        try FileManager.default.copyItem(
            at: defaultCfgURL, to: FFXIVApp.configURL)
        Settings.setDefaultGameConfigPath()
    }
}
