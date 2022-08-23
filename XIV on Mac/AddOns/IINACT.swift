//
//  IINACT.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 15.07.22.
//

import Foundation
import ZIPFoundation
import SeeURL

struct IINACT {
    @available(*, unavailable) private init() {}
    
    private static let dir = Wine.prefix.appendingPathComponent("/drive_c/IINACT")
    private static let exec = dir.appendingPathComponent("IINACT.exe")
    private static let versionFile = dir.appendingPathComponent("version.txt")
    private static let remote = URL(string: "https://github.com/marzent/IINACT/releases/latest/download/IINACT-not-self-contained.zip")!
    private static let remoteVersionURL = URL(string: "https://github.com/marzent/IINACT/raw/main/version")!
    
    private static var version: String? {
        guard let response = HTTPClient.fetch(url: remoteVersionURL) else {
            return nil
        }
        guard response.statusCode == 200 else {
            return nil
        }
        return String(decoding: response.body, as: UTF8.self)
    }
    
    private static let autoLaunchIINACTKey = "AutoLaunchIINACT"
    static var autoLaunch: Bool {
        get {
            return Util.getSetting(settingKey: autoLaunchIINACTKey, defaultValue: false)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: autoLaunchIINACTKey)
        }
    }
    
    static func launchNotify() {
        if autoLaunch {
            launch()
        }
    }
    
    static func launch() {
        install()
        Wine.launch(command: "\"\(exec.path)\"")
        if BunnyHUD.autoLaunch {
            DispatchQueue.global().asyncAfter(deadline: .now() + 15.0) {
                BunnyHUD.launch()
            }
        }
    }
    
    static func install() {
        Util.make(dir: dir)
        let fm = FileManager.default
        if !fm.fileExists(atPath: Wine.prefix.appendingPathComponent("/drive_c/Program Files/dotnet/dotnet.exe").path) {
            Dotnet.installDotNet607()
        }
        if !fm.fileExists(atPath: Wine.prefix.appendingPathComponent("/drive_c/Program Files/dotnet/shared/Microsoft.AspNetCore.App").path) {
            Dotnet.installAspDotNet607()
        }
        let zipURL = Util.cache.appendingPathComponent("IINACT-not-self-contained.zip")
        if let data = try? Data.init(contentsOf: versionFile) {
            let remoteVersion = version
            let readVersion = String(data: data, encoding: .utf8) ?? remoteVersion
            if readVersion != remoteVersion {
                try? fm.removeItem(at: exec)
                try? fm.removeItem(at: zipURL)
                try? (remoteVersion ?? "").write(to: versionFile, atomically: true, encoding: String.Encoding.utf8)
            }
        }
        else {
            try? fm.removeItem(at: exec)
            try? fm.removeItem(at: zipURL)
            try? (version ?? "").write(to: versionFile, atomically: true, encoding: String.Encoding.utf8)
        }
        Dotnet.download(url: remote.absoluteString)
        guard let archive = Archive(url: zipURL, accessMode: .read) else  {
            Log.fatal("Fatal error reading IINACT archive")
            return
        }
        for file in archive {
            try? _ = archive.extract(file, to: dir.appendingPathComponent(file.path))
        }
    }
    
}
