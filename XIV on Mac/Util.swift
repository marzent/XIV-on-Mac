//
//  util.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 22.12.21.
//

import Cocoa

struct Util {
    @available(*, unavailable) private init() {}
    
    static let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last!.appendingPathComponent("XIV on Mac")
    static let wine = Bundle.main.url(forResource: "wine64", withExtension: nil, subdirectory: "wine/bin")!
    static let wineserver = Bundle.main.url(forResource: "wineserver", withExtension: nil, subdirectory: "wine/bin")!
    static let prefix = applicationSupport.appendingPathComponent("game")
    static let cache = applicationSupport.appendingPathComponent("cache")
    static let localSettings = prefix.path + "/drive_c/users/emet-selch/Local Settings/"
    
    class Log: TextOutputStream {
        var logName: String
        
        init(name: String) {
            logName = name
        }
        
        func write(_ string: String) {
            if (string == "\n" || string == "") {
                return
            }
            let log = applicationSupport.appendingPathComponent(logName)
            if let handle = try? FileHandle(forWritingTo: log) {
                handle.seekToEndOfFile()
                handle.write(string.data(using: .utf8)!)
                handle.closeFile()
            } else {
                try? string.data(using: .utf8)?.write(to: log)
            }
        }
    }

    static var logger = Log(name: "app.log")
    static var wineLogger = Log(name: "wine.log")
    
    static func make(dir : String) {
        if !FileManager.default.fileExists(atPath: dir) {
            do {
                try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    static func launch(exec: URL, args: [String], blocking: Bool = false) {
        let task = Process()
        task.environment = enviroment
        task.executableURL = exec
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                print(line, to: &wineLogger)
            } else {
                print("Error decoding data: \(pipe.availableData)", to: &logger)
            }
        }
        do {
            try task.run()
            if blocking {
                task.waitUntilExit()
            }
        }
        catch {
                print("Error starting subprocess")
        }
    }
    
    static func launchWine(args: [String], blocking: Bool = false) {
        launch(exec: wine, args : args, blocking: blocking)
    }
    
    static func launchXL() {
        launchWine(args: [localSettings + "XIVLauncher/XIVLauncher.exe"])
    }
    
    static func killWine(logger: NSTextView?) {
        launch(exec: wineserver, args: ["-k"])
    }
    
    class DXVK: Codable {
        static let settingKey = "DXVK_OPTIONS"
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
            if let data = UserDefaults.standard.value(forKey: Util.DXVK.settingKey) as? Data {
                let s = try? PropertyListDecoder().decode(Util.DXVK.self, from: data)
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
            UserDefaults.standard.set(try? PropertyListEncoder().encode(self), forKey: Util.DXVK.settingKey)
        }
    }
    
    
    static var dxvkOptions = DXVK()
    
    static var enviroment : [String : String] {
        var env = ProcessInfo.processInfo.environment
        env["WINEESYNC"] = "1"
        env["WINEPREFIX"] = prefix.path
        env["WINEDEBUG"] = "-fixme"
        env["DXVK_HUD"] = dxvkOptions.getHud()
        env["DXVK_ASYNC"] = dxvkOptions.getAsync()
        env["DXVK_FRAME_RATE"] = dxvkOptions.getMaxFramerate()
        env["XL_WINEONLINUX"] = "true"
        env["XL_WINEONMAC"] = "true"
        env["MVK_CONFIG_FULL_IMAGE_VIEW_SWIZZLE"] = "0"
        //env["DYLD_PRINT_LIBRARIES"] = "YES"
        env["DYLD_FALLBACK_LIBRARY_PATH"] = Bundle.main.url(forResource: "lib", withExtension: "", subdirectory: "wine")!.path + ":/opt/local/lib:/usr/local/lib:/usr/lib:/usr/libexec:/usr/lib/system:/opt/X11/lib"
        env["DYLD_VERSIONED_LIBRARY_PATH"] = env["DYLD_FALLBACK_LIBRARY_PATH"]
        return env
    }
    
    static func getSetting<T>(settingKey: String, defaultValue: T) -> T {
        let defaults = UserDefaults.standard
        let setting = defaults.object(forKey: settingKey)
        if setting == nil {
            defaults.set(defaultValue, forKey: settingKey)
            return defaultValue
        }
        return setting as! T
    }
}
