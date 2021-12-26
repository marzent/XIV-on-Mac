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
    
    static var enviroment : [String : String] {
        var env = ProcessInfo.processInfo.environment
        env["WINEESYNC"] = "1"
        env["WINEPREFIX"] = prefix.path
        env["WINEDEBUG"] = ""
        if env["DXVK_HUD"] == nil {
            env["DXVK_HUD"] = "compiler"
        }
        env["DXVK_ASYNC"] = "1"
        env["XL_WINEONLINUX"] = "true"
        env["XL_WINEONMAC"] = "true"
        env["MVK_CONFIG_FAST_MATH_ENABLED"] = "1"
        env["MVK_CONFIG_RESUME_LOST_DEVICE"] = "1"
        env["MVK_CONFIG_FULL_IMAGE_VIEW_SWIZZLE"] = "1"
        //env["DYLD_PRINT_LIBRARIES"] = "YES"
        env["DYLD_FALLBACK_LIBRARY_PATH"] = Bundle.main.url(forResource: "lib", withExtension: "", subdirectory: "wine")!.path + ":/usr/lib:/usr/libexec:/usr/lib/system:/opt/X11/lib:/opt/local/lib:/usr/X11/lib:/usr/X11R6/lib"
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
