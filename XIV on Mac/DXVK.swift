//
//  DXVK.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.03.22.
//

import Foundation

struct DXVK {
    @available(*, unavailable) private init() {}
    
    static var options = Options()
    
    static func install() {
        let dxvk_path = Bundle.main.url(forResource: "dxvk", withExtension: nil, subdirectory: "")!
        let dx_dlls = ["d3d9.dll", "d3d10_1.dll", "d3d10.dll", "d3d10core.dll", "dxgi.dll", "d3d11.dll"]
        let system32 = Wine.prefix.appendingPathComponent("drive_c/windows/system32")
        let fm = FileManager.default
        for dll in dx_dlls {
            do {
                let dll_path = system32.appendingPathComponent(dll).path
                if fm.fileExists(atPath: dll_path) {
                    try fm.removeItem(atPath: dll_path)
                }
                try fm.copyItem(atPath: dxvk_path.appendingPathComponent(dll).path, toPath: dll_path)
                Wine.override(dll: dll.components(separatedBy: ".")[0], type: "native")
            }
            catch {
                print("error setting up dxvk dll \(dll)\n", to: &Util.logger)
            }
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
