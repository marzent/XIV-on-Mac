//
//  Wine.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 01.02.22.
//

import Cocoa

struct Wine {
    @available(*, unavailable) private init() {}
    
    static let wine64 = Bundle.main.url(forResource: "wine64", withExtension: nil, subdirectory: "wine/bin")!
    static let wineserver = Bundle.main.url(forResource: "wineserver", withExtension: nil, subdirectory: "wine/bin")!
    static let prefix = Util.applicationSupport.appendingPathComponent("game")
    static let xomData = prefix.appendingPathComponent("drive_c/Program Files/XIV on Mac")

    static var logger = Util.Log(name: "wine.log")
    
    static func launch(args: [String], blocking: Bool = false) {
        Util.launch(exec: wine64, args : args, blocking: blocking)
    }
    
    private static let esyncSettingKey = "EsyncSetting"
    static var esync: Bool {
        get {
            return Util.getSetting(settingKey: esyncSettingKey, defaultValue: true)
        }
        set(newPath) {
            UserDefaults.standard.set(newPath, forKey: esyncSettingKey)
        }
    }
    
    private static let wineDebugSettingKey = "WineDebugSetting"
    static var debug: String {
        get {
            return Util.getSetting(settingKey: wineDebugSettingKey, defaultValue: "-all")
        }
        set(newPath) {
            UserDefaults.standard.set(newPath, forKey: wineDebugSettingKey)
        }
    }

    static func kill() {
        Util.launch(exec: wineserver, args: ["-k"], blocking: true)
    }
    
    static func wait() {
        Util.launch(exec: wineserver, args: ["-w"], blocking: true)
    }
    
    static func addReg(key: String, value: String, data: String) {
        launch(args: ["reg", "add", key, "/v", value, "/d", data, "/f"], blocking: true)
    }
    
    static func override(dll: String, type: String) {
        addReg(key: "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides", value: dll, data: type)
    }
    
    static func set(version: String) {
        launch(args: ["winecfg", "-v", version], blocking: true)
    }
    
    private static let retinaSettingKey = "RetinaMode"
    static var retina: Bool {
        get {
            return Util.getSetting(settingKey: retinaSettingKey, defaultValue: false)
        }
        set(_retina) {
            addReg(key: "HKEY_CURRENT_USER\\Software\\Wine\\Mac Driver", value: "RetinaMode", data: _retina ? "y" : "n")
            UserDefaults.standard.set(_retina, forKey: retinaSettingKey)
        }
    }
    
    private static var timebase: mach_timebase_info = mach_timebase_info()
    static var tickCount: UInt64 {
        if timebase.denom == 0 {
            mach_timebase_info(&timebase)
        }
        let machtime = mach_continuous_time() //maybe mach_absolute_time for older wine versions?
        let numer = UInt64(timebase.numer)
        let denom = UInt64(timebase.denom)
        let monotonic_time = machtime * numer / denom / 100
        return monotonic_time / 10000
    }
    
}
