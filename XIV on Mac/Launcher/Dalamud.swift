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
    
    static let fm = FileManager.default
    static let path = Wine.xomData.appendingPathComponent("Dalamud")
    static let localAssets =  Wine.prefix.appendingPathComponent("drive_c/users/emet-selch/Application Data/XIVLauncher/dalamudAssets/dev/")
    static let runtime = Wine.prefix.appendingPathComponent("drive_c/users/emet-selch/Application Data/XIVLauncher/runtime")
    
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

    static func install() {
        if needsUpdate() {
            purge()
        }
        Setup.download(url: remote.distrib)
        Setup.download(url: nativeLauncher.remote)
        try? fm.copyItem(atPath: Util.cache.appendingPathComponent(nativeLauncher.exec).path, toPath: nativeLauncher.path)
        try? fm.unzipItem(at: Util.cache.appendingPathComponent("latest.zip"), to: path)
        for asset in remote.assets!.assets {
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
    
    static func launch(args: [String]) {
        let output = Util.launchToString(exec: Wine.wine64, args: [nativeLauncher.path] + args)
        let pid = String(output.split(separator: "\n").last!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
            Wine.launch(args: [path.appendingPathComponent("Dalamud.Injector.exe").path, pid])
        }
    }
    
    private static func needsUpdate() -> Bool {
        do {
            let deps = try String(contentsOf: path.appendingPathComponent("Dalamud.deps.json"), encoding: .utf8)
            let head = String(deps.prefix(300))
            if let range = head.range(of: #"(?<=Dalamud\/).*(?=":)"#, options: .regularExpression) {
                let localVersion = head[range]
                if localVersion == remote.version!.assemblyVersion {
                    return false
                }
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
    
}
