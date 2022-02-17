//
//  Dalamud.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 03.02.22.
//

import Foundation
import ZIPFoundation

struct Dalamud {
    @available(*, unavailable) private init() {}
    
    struct nativeLauncher {
        static let exec = "NativeLauncher.exe"
        static let path = Wine.xomData.appendingPathComponent(exec).path
        static let remote = "https://github.com/redstrate/nativelauncher/releases/download/v1.0.0/" + exec
    }
    
    
    struct Version: Codable {
        let assemblyVersion, supportedGameVer, runtimeVersion: String
        let runtimeRequired: Bool

        enum CodingKeys: String, CodingKey {
            case assemblyVersion = "AssemblyVersion"
            case supportedGameVer = "SupportedGameVer"
            case runtimeVersion = "RuntimeVersion"
            case runtimeRequired = "RuntimeRequired"
        }
    }
    
    struct Assets: Codable {
        
        struct Asset: Codable {
            let url: String
            let fileName: String
            let hash: String?

            enum CodingKeys: String, CodingKey {
                case url = "Url"
                case fileName = "FileName"
                case hash = "Hash"
            }
        }
        
        let version: Int
        let assets: [Asset]

        enum CodingKeys: String, CodingKey {
            case version = "Version"
            case assets = "Assets"
        }
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
    
    static let fm = FileManager.default
    static let path = Wine.xomData.appendingPathComponent("Dalamud")
    static let localAssets = Wine.xomData.appendingPathComponent("Dalamud Assets")
    static let runtime = Wine.xomData.appendingPathComponent("dotNET Runtime")
    
    private struct remote {
        
        static let distrib = "https://goatcorp.github.io/dalamud-distrib/latest.zip"
        
        static var assets: Assets? {
            var ret: Assets?
            let url = URL(string: "https://goatcorp.github.io/DalamudAssets/asset.json")!
            let semaphore = DispatchSemaphore(value: 0)
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    let jsonDecoder = JSONDecoder()
                    do {
                        ret = try jsonDecoder.decode(Assets.self, from: data)
                    } catch {
                        print(error, to: &Util.logger)
                    }
                }
                semaphore.signal()
            }
            task.resume()
            semaphore.wait()
            return ret
        }
        
        static var version: Version? {
            var ret: Version?
            let url = URL(string: "https://goatcorp.github.io/dalamud-distrib/version")!
            let semaphore = DispatchSemaphore(value: 0)
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    let jsonDecoder = JSONDecoder()
                    do {
                        ret = try jsonDecoder.decode(Version.self, from: data)
                    } catch {
                        print(error, to: &Util.logger)
                    }
                }
                semaphore.signal()
            }
            task.resume()
            semaphore.wait()
            return ret
        }
    }
    
    
    private static let injectionSettingKey = "InjectionDelaySetting"
    static var delay: Double {
        get {
            return Util.getSetting(settingKey: injectionSettingKey, defaultValue: 7.0)
        }
        set(newDelay) {
            UserDefaults.standard.set(newDelay, forKey: injectionSettingKey)
        }
    }
    
    private static let mbCollectionSettingKey = "MBCollectionSetting"
    static var mbCollection: Bool {
        get {
            return Util.getSetting(settingKey: mbCollectionSettingKey, defaultValue: true)
        }
        set(collect) {
            UserDefaults.standard.set(collect, forKey: mbCollectionSettingKey)
        }
    }
    
    private static func install() {
        if needsUpdate() {
            NotificationCenter.default.post(name: .loginInfo, object: nil, userInfo: [Notification.status.info: "Updating Dalamud"])
            purge()
        }
        Setup.download(url: remote.distrib)
        Setup.download(url: nativeLauncher.remote)
        try? fm.copyItem(atPath: Util.cache.appendingPathComponent(nativeLauncher.exec).path, toPath: nativeLauncher.path)
        try? fm.unzipItem(at: Util.cache.appendingPathComponent("latest.zip"), to: path)
        guard let remoteAssets = remote.assets else {
            print("Could not get Dalamud Assets", to: &Util.logger)
            return
        }
        for asset in remoteAssets.assets {
            FileDownloader.loadFileSync(url: URL(string: asset.url)!,
                                        destination: URL(fileURLWithPath: localAssets.path + "/" + asset.fileName).deletingLastPathComponent())
            {(path, error) in
                print("Dalamud Asset downloaded to: \(path!)\n", to: &Util.logger)
            }
        }
        try? fm.moveItem(at: localAssets.appendingPathComponent("UIRes/FFXIV_Lodestone_SSF.ttf"), to: localAssets.appendingPathComponent("UIRes/gamesym.ttf")) //WHY???
        installRuntime()
    }
    
    private static func installRuntime() {
        if !remote.version!.runtimeRequired {
            return
        }
        let version = remote.version!.runtimeVersion
        Setup.download(url: "https://dotnetcli.azureedge.net/dotnet/Runtime/\(version)/dotnet-runtime-\(version)-win-x64.zip")
        Setup.download(url: "https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/\(version)/windowsdesktop-runtime-\(version)-win-x64.zip")
        try? fm.unzipItem(at: Util.cache.appendingPathComponent("dotnet-runtime-\(version)-win-x64.zip"), to: runtime)
        try? fm.unzipItem(at: Util.cache.appendingPathComponent("windowsdesktop-runtime-\(version)-win-x64.zip"), to: runtime)
    }
    
    private static func needsUpdate() -> Bool {
        //Loosely inspired by https://github.com/redstrate/xivlauncher/ and even more janky :)
        do {
            let deps = try String(contentsOf: path.appendingPathComponent("Dalamud.deps.json"), encoding: .utf8)
            let head = String(deps.prefix(300))
            if let range = head.range(of: #"(?<=Dalamud\/).*(?=":)"#, options: .regularExpression) {
                let localVersion = head[range]
                if let remoteVersion = remote.version {
                    return localVersion != remoteVersion.assemblyVersion
                }
                return false
            }
        }
        catch {
            return true
        }
        return true
    }
    
    private static func purge() {
        for toRemove in [Util.cache.appendingPathComponent("latest.zip"),
                         localAssets,
                         path,
                         runtime] {
            try? fm.removeItem(at: toRemove)
        }
    }
    
    static func launch(args: [String], region: FFXIVRegion, gameVersion: String) {
        install()
        NotificationCenter.default.post(name: .loginInfo, object: nil, userInfo: [Notification.status.info: "Starting Wine"])
        let output = Util.launchToString(exec: Wine.wine64, args: [nativeLauncher.path] + args)
        let pid = String(output.split(separator: "\n").last!)
        let startInfo = StartInfo(workingDirectory: nil,
                                  configurationPath: "C:\\Program Files\\XIV on Mac\\dalamudConfig.json",
                                  pluginDirectory: "C:\\Program Files\\XIV on Mac\\installedPlugins",
                                  defaultPluginDirectory: "C:\\Program Files\\XIV on Mac\\devPlugins",
                                  assetDirectory: "C:\\Program Files\\XIV on Mac\\Dalamud Assets",
                                  language: Int(region.language.rawValue),
                                  gameVersion: gameVersion,
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
