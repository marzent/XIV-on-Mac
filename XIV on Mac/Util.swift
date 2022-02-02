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
    static let cache = applicationSupport.appendingPathComponent("cache")
    
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
        task.qualityOfService = QualityOfService.userInteractive
        task.environment = enviroment
        task.executableURL = exec
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                print(line, to: &Wine.logger)
            } else {
                print("Error decoding data: \(pipe.availableData)\n", to: &logger)
            }
        }
        do {
            try task.run()
        }
        catch {
            print("Error starting subprocess", to: &logger)
        }
        if blocking {
            task.waitUntilExit()
        }
    }
    
    private static let launchSettingKey = "LaunchPath"
    static var launchPath: String {
        get {
            return Util.getSetting(settingKey: launchSettingKey, defaultValue: "")
        }
        set(newPath) {
            UserDefaults.standard.set(newPath, forKey: launchSettingKey)
        }
    }
    
    static func launchExec(terminating: Bool = true) {
        Wine.launch(args : [launchPath], blocking: false)
        if terminating {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 10.0) {
                Wine.wait()
                DispatchQueue.main.async {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
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
        env["LANG"] = "en_US" //needed to run when system language is set to 日本語
        env["WINEESYNC"] = Wine.esync ? "1" : "0"
        env["WINEPREFIX"] = Wine.prefix.path
        env["WINEDEBUG"] = Wine.debug
        env["DXVK_HUD"] = dxvkOptions.getHud()
        env["DXVK_ASYNC"] = dxvkOptions.getAsync()
        env["DXVK_FRAME_RATE"] = dxvkOptions.getMaxFramerate()
        env["XL_WINEONLINUX"] = "true"
        env["XL_WINEONMAC"] = "true"
        env["MVK_CONFIG_FULL_IMAGE_VIEW_SWIZZLE"] = "0"
        env["MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS"] = "1"
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
