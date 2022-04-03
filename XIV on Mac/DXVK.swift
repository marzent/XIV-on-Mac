//
//  DXVK.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.03.22.
//

import Foundation

struct DXVK {
    @available(*, unavailable) private init() {}
    
    static let userCache = Wine.prefix.appendingPathComponent("drive_c/ffxiv_dx11.dxvk-cache")
    static var options = Options()
    
    private static let modernMVKKey = "ModernMoltenVK"
    static var modernMVK: Bool {
        get {
            UserDefaults.standard.bool(forKey: modernMVKKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: modernMVKKey)
        }
    }
    
    static func install() {
        let dxvkPath = Bundle.main.url(forResource: "dxvk", withExtension: nil, subdirectory: "")!
        let dxDlls = ["d3d9.dll", "d3d10_1.dll", "d3d10.dll", "d3d10core.dll", "dxgi.dll", "d3d11.dll"]
        let system32 = Wine.prefix.appendingPathComponent("drive_c/windows/system32")
        let fm = FileManager.default
        for dll in dxDlls {
            let winDllPath = system32.appendingPathComponent(dll).path
            let dxvkDllPath = dxvkPath.appendingPathComponent(dll).path
            if fm.contentsEqual(atPath: winDllPath, andPath: dxvkDllPath) {
                continue
            }
            NotificationCenter.default.post(name: .loginInfo, object: nil, userInfo: [Notification.status.info: "Installing DXVK"])
            Wine.override(dll: dll.components(separatedBy: ".")[0], type: "native")
            if fm.fileExists(atPath: winDllPath) {
                do {
                    try fm.removeItem(atPath: winDllPath)
                }
                catch {
                    print("DXVK: error deleting wine dx dll \(winDllPath)\n\(error)\n", to: &Util.logger)
                }
            }
            do {
                try fm.copyItem(atPath: dxvkDllPath, toPath: winDllPath)
            }
            catch {
                print("DXVK: error copying dxvk dll \(error)\n", to: &Util.logger)
            }
        }
        let stateCacheName = "ffxiv_dx11.dxvk-cache-base"
        let stateCacheBundled = dxvkPath.appendingPathComponent(stateCacheName)
        let stateCachePrefix = Wine.prefix.appendingPathComponent("drive_c/" + stateCacheName)
        if fm.contentsEqual(atPath: stateCacheBundled.path, andPath: stateCachePrefix.path) {
            return
        }
        try? fm.removeItem(at: stateCachePrefix)
        try? fm.copyItem(at: stateCacheBundled, to: stateCachePrefix)
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
            if let data = UserDefaults.standard.value(forKey: DXVK.Options.settingKey) as? Data {
                let s = try? PropertyListDecoder().decode(DXVK.Options.self, from: data)
                async = s!.async
                maxFramerate = s!.maxFramerate
                hud = s!.hud
                hudScale = s!.hudScale
                
            } else {
                save()
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
        
        func save() {
            UserDefaults.standard.set(try? PropertyListEncoder().encode(self), forKey: DXVK.Options.settingKey)
        }
    }
}
