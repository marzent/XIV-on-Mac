//
//  DXVK.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.03.22.
//

import CompatibilityTools
import Foundation

enum Dxvk {
    static var options = Options()
    private static let userCacheURL = Wine.prefix.appendingPathComponent(
        "drive_c/ffxiv_dx11.dxvk-cache")
    private static let dxvkPath = Bundle.main.url(
        forResource: "dxvk", withExtension: nil, subdirectory: "")!
    private static let d3d11Dll = dxvkPath.appendingPathComponent("d3d11.dll")
    private static let baseCacheBundled = dxvkPath.appendingPathComponent(
        "ffxiv_dx11.dxvk-cache-base")

    static func install() {
        GraphicsInstaller.install(dll: d3d11Dll)
        
        // Check if user cache exists
        if FileManager.default.fileExists(atPath: userCacheURL.path) {
            // Try to parse and merge caches
            let userCache = try? DxvkStateCache(
                inputData: (try? Data(contentsOf: userCacheURL)) ?? Data())
            let baseCache = try? DxvkStateCache(
                inputData: (try? Data(contentsOf: baseCacheBundled)) ?? Data())
            
            if let userCache = userCache, let baseCache = baseCache {
                guard userCache.header.version == baseCache.header.version else {
                    Log.warning("[DXVK] Base and user cache versions do not match, resetting")
                    try? resetCache()
                    return
                }
                // Merge caches
                let mergedCache = DxvkStateCache(
                    header: userCache.header,
                    entries: Array(Set(userCache.entries + baseCache.entries)))
                do {
                    try mergedCache.rawData.write(to: userCacheURL)
                    Log.information("[DXVK] Merged cache successfully")
                } catch {
                    Log.error("[DXVK] Failed to write merged cache: \(error.localizedDescription)")
                }
            } else if userCache == nil && baseCache == nil {
                Log.warning("[DXVK] Both caches corrupt, keeping existing user cache")
            }
            // If only one cache is corrupt, keep the existing user cache
        } else {
            // No user cache exists - copy base cache directly without parsing
            Log.information("[DXVK] No user cache found, copying base cache")
            try? resetCache()
        }
    }

    static func resetCache() throws {
        let fm = FileManager.default
        try fm.removeItem(at: userCacheURL)
        try fm.copyItem(at: baseCacheBundled, to: userCacheURL)
    }

    class Options: Codable {
        static let settingKey = "DxvkOptions"
        var asyncShaders = true
        var maxFramerate = 0
        private var hud = [
            "devinfo": false,  // Displays the name of the GPU and the driver version.
            "fps": false,  // Shows the current frame rate.
            "frametimes": false,  // Shows a frame time graph.
            "submissions": false,  // Shows the number of command buffers submitted per frame.
            "drawcalls": false,  // Shows the number of draw calls and render passes per frame.
            "pipelines": false,  // Shows the total number of graphics and compute pipelines.
            "memory": false,  // Shows the amount of device memory allocated and used.
            "gpuload": false,  // Shows estimated GPU load. May be inaccurate.
            "version": false,  // Shows DXVK version.
            "api": false,  // Shows the D3D feature level used by the application.
            "compiler": true,
        ]  // Shows shader compiler activity
        var hudScale = 1.0

        init() {
            if let data = UserDefaults.standard.value(
                forKey: Dxvk.Options.settingKey) as? Data
            {
                guard
                    let s = try? PropertyListDecoder().decode(
                        Dxvk.Options.self, from: data)
                else {
                    save(withSetup: false)
                    return
                }
                asyncShaders = s.asyncShaders
                maxFramerate = s.maxFramerate
                hud = s.hud
                hudScale = s.hudScale

            } else {
                save(withSetup: false)
            }
        }

        func getAsync() -> String {
            return asyncShaders ? "1" : "0"
        }

        func getMaxFramerate() -> String {
            return String(maxFramerate)
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

        func getHud(option: String) -> Bool {
            hud[option]!
        }

        func setHud(option: String, to: Bool) throws {
            guard let originalOption = hud[option] else {
                throw DxvkError.invalidHudKey
            }
            guard originalOption != to else {
                return
            }
            hud[option] = to
            save()
        }

        func setAllHudOptions(to: Bool) {
            for key in Array(hud.keys) {
                hud[key] = to
            }
            save()
        }

        func save(withSetup: Bool = true) {
            UserDefaults.standard.set(
                try? PropertyListEncoder().encode(self),
                forKey: Dxvk.Options.settingKey)
            if withSetup {
                DispatchQueue.main.async {
                    Wine.setup()
                }
            }
        }
    }
}
