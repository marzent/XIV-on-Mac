//
//  DXVK.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.03.22.
//

import Foundation
import CompatibilityTools

struct Dxvk {
    @available(*, unavailable) private init() {}
    
    static let userCacheURL = Wine.prefix.appendingPathComponent("drive_c/ffxiv_dx11.dxvk-cache")
    static var options = Options()
    
    static func install() {
        let dxvkPath = Bundle.main.url(forResource: "dxvk", withExtension: nil, subdirectory: "")!
        let dxDlls = ["d3d10_1.dll", "d3d10.dll", "d3d10core.dll", "dxgi.dll", "d3d11.dll"]
        let system32 = Wine.prefix.appendingPathComponent("drive_c/windows/system32")
        Util.make(dir: system32)
        let fm = FileManager.default
        for dll in dxDlls {
            let winDllPath = system32.appendingPathComponent(dll).path
            let dxvkDllPath = dxvkPath.appendingPathComponent(dll).path
            if fm.contentsEqual(atPath: winDllPath, andPath: dxvkDllPath) {
                continue
            }
            if fm.fileExists(atPath: winDllPath) {
                do {
                    try fm.removeItem(atPath: winDllPath)
                }
                catch {
                    Log.error("[DXVK] error deleting wine dx dll \(winDllPath)\n\(error)")
                }
            }
            do {
                try fm.copyItem(atPath: dxvkDllPath, toPath: winDllPath)
            }
            catch {
                Log.error("[DXVK] error copying dxvk dll \(error)")
            }
        }
        let baseCacheName = "ffxiv_dx11.dxvk-cache-base"
        let baseCacheBundled = dxvkPath.appendingPathComponent(baseCacheName)
        let baseCachePrefix = Wine.prefix.appendingPathComponent("drive_c/" + baseCacheName)
        try? fm.removeItem(at: baseCachePrefix)
        let userCache = try? DxvkStateCache(inputData: (try? Data(contentsOf: userCacheURL)) ?? Data())
        guard let baseCache = try? DxvkStateCache(inputData: (try? Data(contentsOf: baseCacheBundled)) ?? Data()) else {
            Log.warning("[DXVK] Corrupt base cache")
            return
        }
        if let userCache = userCache {
            guard userCache.header.version == baseCache.header.version else {
                Log.warning("[DXVK] Base and user cache versions do not match")
                return
            }
            let zoeyEntryHash: [UInt8] = [153, 106, 41, 216, 87, 200, 23, 183, 42, 119, 59, 206, 160, 195, 34, 186, 3, 214, 205, 51]
            if userCache.entries.map({$0.sha1Hash}).contains(zoeyEntryHash) {
                Log.warning("[DXVK] You are having an entry in your user cache that is known to cause issues, consider deleting your user state cache")
            }
            let mergedCache = DxvkStateCache(header: userCache.header, entries: Array(Set(userCache.entries + baseCache.entries)))
            do {
                try mergedCache.rawData.write(to: userCacheURL)
            } catch {
                Log.error(error.localizedDescription)
            }
        } else { //user cache non-existent or corrupt
            try? fm.removeItem(at: userCacheURL)
            try? fm.copyItem(at: baseCacheBundled, to: userCacheURL)
        }
    }
    
    class Options: Codable {
        static let settingKey = "DxvkOptions"
        var async = true
        var maxFramerate = 0
        var hud = ["devinfo": false, //Displays the name of the GPU and the driver version.
                   "fps": false, //Shows the current frame rate.
                   "frametimes": false, //Shows a frame time graph.
                   "submissions": false, //Shows the number of command buffers submitted per frame.
                   "drawcalls": false, //Shows the number of draw calls and render passes per frame.
                   "pipelines": false, //Shows the total number of graphics and compute pipelines.
                   "memory": false, //Shows the amount of device memory allocated and used.
                   "gpuload": false, //Shows estimated GPU load. May be inaccurate.
                   "version": false, //Shows DXVK version.
                   "api": false, //Shows the D3D feature level used by the application.
                   "compiler": true] //Shows shader compiler activity
        var hudScale = 1.0
        
        init() {
            if let data = UserDefaults.standard.value(forKey: Dxvk.Options.settingKey) as? Data {
                let s = try? PropertyListDecoder().decode(Dxvk.Options.self, from: data)
                async = s!.async
                maxFramerate = s!.maxFramerate
                hud = s!.hud
                hudScale = s!.hudScale
                
            } else {
                save(withSetup: false)
            }
        }
        
        func getAsync() -> String {
            return self.async ? "1": "0"
        }
        
        func getMaxFramerate() -> String {
            return String(self.maxFramerate)
        }
        
        func getHud() -> String {
            var params = ["scale=\(hudScale)"]
            for (option, enabled) in hud {
                if enabled {
                    params.append(option)
                }
            }
            return params.joined(separator: ",")
        }
        
        func save(withSetup: Bool = true) {
            UserDefaults.standard.set(try? PropertyListEncoder().encode(self), forKey: Dxvk.Options.settingKey)
            if withSetup {
                Wine.setup()
            }
        }
    }
    
    private static let modernMVKKey = "ModernMoltenVK"
    static var modernMVK: Bool {
        get {
            UserDefaults.standard.bool(forKey: modernMVKKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: modernMVKKey)
        }
    }
    
}
