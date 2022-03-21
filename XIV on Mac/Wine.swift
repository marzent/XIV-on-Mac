//
//  Wine.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 01.02.22.
//

import Foundation

struct Wine {
    @available(*, unavailable) private init() {}
    
    static let wine64 = Bundle.main.url(forResource: "wine64", withExtension: nil, subdirectory: "wine/bin")!
    static let wineserver = Bundle.main.url(forResource: "wineserver", withExtension: nil, subdirectory: "wine/bin")!
    static let prefix = Util.applicationSupport.appendingPathComponent("game")
    static let xomData = prefix.appendingPathComponent("drive_c/Program Files/XIV on Mac")

    static var logger = Util.Log(name: "wine.log")
    
    static func launch(args: [String], blocking: Bool = false) {
        Util.launch(exec: wine64, args : args, blocking: blocking, wineLog: true)
    }
    
    static var processes: [(pid: Int, name: String)] {
        let infoProc = Util.launchToString(exec: wine64, args: ["winedbg", "--command", "info proc"])
        let lines = infoProc.replacingOccurrences(of: "\\_", with: "").components(separatedBy: "\n")
        guard let headerIndex = lines.firstIndex(of: " pid      threads  executable (all id:s are in hex)") else {
            return []
        }
        let procLines = lines.dropFirst(headerIndex + 1).dropLast().map {$0.split(separator: " ")}
        return procLines.filter {$0.count == 3}.map {(pid: Int($0[0], radix: 16) ?? 0, name: String($0[2].dropFirst().dropLast())) }
    }
    
    static func pidOf(processName: String) -> Int {
        processes.filter {$0.name == processName}.first?.pid ?? 0
    }
    
    static func taskKill(pid: Int) {
        launch(args: ["taskkill", "/f", "/pid", "\(pid)"], blocking: true)
    }
    
    static func taskKill(processName: String) {
        launch(args: ["taskkill", "/f", "/im" , processName], blocking: true)
    }
    
    static func touchDocuments() {
        launch(args: ["cmd", "/c", "dir", "%userprofile%/My Documents", ">", "nul"])
    }
    
    private static let esyncSettingKey = "EsyncSetting"
    static var esync: Bool {
        get {
            Util.getSetting(settingKey: esyncSettingKey, defaultValue: true)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: esyncSettingKey)
        }
    }
    
    private static let wineDebugSettingKey = "WineDebugSetting"
    static var debug: String {
        get {
            Util.getSetting(settingKey: wineDebugSettingKey, defaultValue: "-all")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: wineDebugSettingKey)
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
            Util.getSetting(settingKey: retinaSettingKey, defaultValue: false)
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
