//
//  Dalamud.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 03.02.22.
//

import Foundation
import ZIPFoundation
import SeeURL

struct Dalamud {
    @available(*, unavailable) private init() {}
    
    struct Version: Codable {
        
        struct Changelog: Codable {
            
            struct Change: Codable {
                let message, author, sha, date: String
            }
            
            let date, version: String
            let changes: [Change]
        }
        
        let key: String?
        let track, assemblyVersion, runtimeVersion: String
        let runtimeRequired: Bool
        let supportedGameVer: String
        let changelog: Changelog?
        let downloadURL: String
        
        enum CodingKeys: String, CodingKey {
            case key, track, assemblyVersion, runtimeVersion, runtimeRequired, supportedGameVer, changelog
            case downloadURL = "downloadUrl"
        }
    }
    
    struct Assets: Codable {
        
        struct Asset: Codable {
            let url: String
            let fileName: String
            let hash: String?
        }
        
        let version: Int
        let assets: [Asset]
    }
    
    struct StartInfo: Codable {
        let workingDirectory: String?
        let configurationPath, pluginDirectory, defaultPluginDirectory, assetDirectory: String
        let language: Int
        let gameVersion: String
        let optOutMBCollection: Bool
        let delayInitializeMS: Int

        enum CodingKeys: String, CodingKey {
            case workingDirectory = "WorkingDirectory"
            case configurationPath = "ConfigurationPath"
            case pluginDirectory = "PluginDirectory"
            case defaultPluginDirectory = "DefaultPluginDirectory"
            case assetDirectory = "AssetDirectory"
            case language = "Language"
            case gameVersion = "GameVersion"
            case optOutMBCollection = "OptOutMbCollection"
            case delayInitializeMS = "DelayInitializeMs"
        }
    }
    
    private static let fm = FileManager.default
    private static let path = Wine.xomData.appendingPathComponent("Dalamud")
    private static let runtimeLocation = Wine.xomData.appendingPathComponent("dotNET Runtime")
    // Dalamud injection delay seems to be heavily system dependent for some reason.
    // But, while the default 7 seems to work great on Intel system we've seen a lot of evidence
    // in the Discord support channel that 2 works much better on Apple Silicon; so, it's easy enough to
    // have two different defaults.
#if arch(arm64)
    static let defaultInjectionDelay = 2.0
#else
    static let defaultInjectionDelay = 7.0
#endif
    
    private struct Remote {
        
        static var assets: Assets? {
            let url = URL(string: "https://kamori.goats.dev/Dalamud/Asset/Meta?appId=xom")!
            guard let response = HTTPClient.fetch(url: url) else {
                return nil
            }
            guard response.statusCode == 200 else {
                return nil
            }
            let jsonDecoder = JSONDecoder()
            do {
                return try jsonDecoder.decode(Assets.self, from: response.body)
            } catch {
                print(error, to: &Util.logger)
                return nil
            }
        }
        
        static var version: Version? {
            let stagingTrack = "net5"
            let url = URL(string: "https://kamori.goats.dev/Dalamud/Release/VersionInfo?track=\(staging ? stagingTrack : "release")&appId=xom")!
            guard let response = HTTPClient.fetch(url: url) else {
                return nil
            }
            guard response.statusCode == 200 else {
                return nil
            }
            let jsonDecoder = JSONDecoder()
            do {
                return try jsonDecoder.decode(Version.self, from: response.body)
            } catch {
                print(error, to: &Util.logger)
                return nil
            }
        }
    }
    
    
    private static let injectionSettingKey = "InjectionDelaySetting"
    static var delay: Double {
        get {
            return Util.getSetting(settingKey: injectionSettingKey, defaultValue: Dalamud.defaultInjectionDelay)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: injectionSettingKey)
        }
    }
    
    private static let mbCollectionSettingKey = "MBCollectionSetting"
    static var mbCollection: Bool {
        get {
            return Util.getSetting(settingKey: mbCollectionSettingKey, defaultValue: true)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: mbCollectionSettingKey)
        }
    }
    
    private static let stagingKey = "DalamudStaging"
    static var staging: Bool {
        get {
            UserDefaults.standard.bool(forKey: stagingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: stagingKey)
        }
    }
    
    private static let versionFile = path.appendingPathComponent("version.txt")
    static var assemblyVersion: String {
        get {
            guard let data = try? Data.init(contentsOf: versionFile) else {
                return ""
            }
            return String(data: data, encoding: .utf8) ?? ""
        }
        set {
            Util.make(dir: path)
            let fm = FileManager.default
            do {
                if fm.fileExists(atPath: versionFile.path) {
                    try fm.removeItem(atPath: versionFile.path)
                }
                try newValue.write(to: versionFile, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("Error writing Dalamud version file:\n\(error)\n", to: &Util.logger)
            }
        }
    }
    
    private static let runtimeVersionFile = runtimeLocation.appendingPathComponent("version.txt")
    static var runtimeVersion: String {
        get {
            guard let data = try? Data.init(contentsOf: runtimeVersionFile) else {
                return ""
            }
            return String(data: data, encoding: .utf8) ?? ""
        }
        set {
            Util.make(dir: runtimeLocation)
            let fm = FileManager.default
            do {
                if fm.fileExists(atPath: runtimeVersionFile.path) {
                    try fm.removeItem(atPath: runtimeVersionFile.path)
                }
                try newValue.write(to: runtimeVersionFile, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("Error writing Dalamud runtime version file:\n\(error)\n", to: &Util.logger)
            }
        }
    }
    
      private static func ensureInstall() {
        guard let version = Remote.version else {
            print("Could not check for Dalamud due to network error\n", to: &Util.logger)
            return
        }
        if assemblyVersion == version.assemblyVersion {
            return
        }
        NotificationCenter.default.post(name: .loginInfo, object: nil, userInfo: [Notification.status.info: "Updating Dalamud"])
        let dalamudDownload = Util.cache.appendingPathComponent("dalamud.zip")
        try? fm.removeItem(at: dalamudDownload)
        try? HTTPClient.fetchFile(url: URL(string: version.downloadURL)!, destinationUrl: dalamudDownload)
        try? fm.removeItem(at: path)
        try? fm.unzipItem(at: dalamudDownload, to: path)
        installRuntime(version)
        assemblyVersion = version.assemblyVersion
    }
    
    private static func updateAssets() {
        let localAssets = Wine.xomData.appendingPathComponent("Dalamud Assets")
        guard let remoteAssets = Remote.assets else {
            print("Could not get Dalamud Assets\n", to: &Util.logger)
            return
        }
        for asset in remoteAssets.assets {
            let localAsset = URL(fileURLWithPath: localAssets.path + "/" + asset.fileName)
            let (localHash, _) = (try? Encryption.sha1(file: localAsset)) ?? ("", 0)
            if let remoteHash = asset.hash {
                if localHash.uppercased() != remoteHash {
                    try? fm.removeItem(atPath: localAsset.path)
                }
            }
            try? HTTPClient.fetchFile(url: URL(string: asset.url)!, destinationUrl: localAsset)
        }
    }
    
    private static func installRuntime(_ version: Version) {
        guard version.runtimeRequired else {
            return
        }
        let netVersion = version.runtimeVersion
        if runtimeVersion == netVersion {
            return
        }
        let dotnetRuntime = URL(string: "https://dotnetcli.azureedge.net/dotnet/Runtime/\(netVersion)/dotnet-runtime-\(netVersion)-win-x64.zip")!
        let windowsDesktopRuntime = URL(string: "https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/\(netVersion)/windowsdesktop-runtime-\(netVersion)-win-x64.zip")!
        try? HTTPClient.fetchFile(url: dotnetRuntime)
        try? HTTPClient.fetchFile(url: windowsDesktopRuntime)
        try? fm.removeItem(at: runtimeLocation)
        try? fm.unzipItem(at: Util.cache.appendingPathComponent("dotnet-runtime-\(netVersion)-win-x64.zip"), to: runtimeLocation)
        try? fm.unzipItem(at: Util.cache.appendingPathComponent("windowsdesktop-runtime-\(netVersion)-win-x64.zip"), to: runtimeLocation)
        runtimeVersion = netVersion
    }
    
    static func preLaunch() {
        ensureInstall()
        updateAssets()
        DiscordBridge.setPresence()
    }
    
    static func launch() {
        guard Remote.version?.supportedGameVer == FFXIVRepo.game.ver else {
            return
        }
        let pid = String(Wine.pidOf(processName: "ffxiv_dx11.exe"))
        let startInfo = StartInfo(workingDirectory: nil,
                                  configurationPath: "C:\\Program Files\\XIV on Mac\\dalamudConfig.json",
                                  pluginDirectory: "C:\\Program Files\\XIV on Mac\\installedPlugins",
                                  defaultPluginDirectory: "C:\\Program Files\\XIV on Mac\\devPlugins",
                                  assetDirectory: "C:\\Program Files\\XIV on Mac\\Dalamud Assets",
                                  language: Int(FFXIVSettings.language.rawValue),
                                  gameVersion: FFXIVRepo.game.ver,
                                  optOutMBCollection: !mbCollection,
                                  delayInitializeMS: 0) //we handle delay ourselves
        let encodedStartInfo = try! JSONEncoder().encode(startInfo).base64EncodedString()
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            print("Starting Dalamud with StartInfo:\n", encodedStartInfo, "\n", to: &Util.logger)
            NotificationCenter.default.post(name: .loginInfo, object: nil, userInfo: [Notification.status.info: "Injecting Dalamud"])
            Wine.launch(args: [path.appendingPathComponent("Dalamud.Injector.exe").path, pid, encodedStartInfo])
        }
    }
    
}
