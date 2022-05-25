//
//  Wine.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 01.02.22.
//

import Foundation
import CompatibilityTools

struct Wine {
    @available(*, unavailable) private init() {}
    
    static let wineBinURL = Bundle.main.url(forResource: "bin", withExtension: nil, subdirectory: "wine")!
    static let prefix = Util.applicationSupport.appendingPathComponent("wineprefix")
    
    static func setup() {
        let mvkPath = Bundle.main.url(forResource: Dxvk.modernMVK ? "modern" : "stable", withExtension: "", subdirectory: "MoltenVK")!.path
        let winePath = Bundle.main.url(forResource: "lib", withExtension: "", subdirectory: "wine")!.path
        let libSearchPath = [mvkPath, winePath, "/opt/local/lib", "/usr/local/lib", "/usr/lib", "/usr/libexec", "/usr/lib/system", "/opt/X11/lib"].joined(separator: ":")
        addEnviromentVariable("DYLD_FALLBACK_LIBRARY_PATH", libSearchPath)
        addEnviromentVariable("DYLD_VERSIONED_LIBRARY_PATH", libSearchPath)
        addEnviromentVariable("MVK_CONFIG_RESUME_LOST_DEVICE", "1")
        addEnviromentVariable("XL_WINEONLINUX", "true")
        addEnviromentVariable("DXVK_STATE_CACHE_PATH", "C:\\")
        addEnviromentVariable("DXVK_LOG_PATH", "C:\\")
        createCompatToolsInstance(Wine.wineBinURL.path, Wine.debug, Wine.esync)
    }
    
    static func launch(command: String, blocking: Bool = false) {
        if blocking {
            runInPrefixBlocking(command)
        }
        else {
            runInPrefix(command)
        }
    }
    
    static func pidOf(processName: String) -> Int {
        pidsOf(processName: processName).first ?? 0
    }
    
    static func pidsOf(processName: String) -> [Int] {
        Array(String(cString: getProcessIds(processName)).split(separator: " ").compactMap {Int($0)})
    }
    
    static func taskKill(pid: Int) {
        launch(command: "taskkill /f /pid \(pid)", blocking: true)
    }
    
    static func taskKill(processName: String) {
        launch(command: "taskkill /f /im \(processName)", blocking: true)
    }
    
    static func touchDocuments() {
        launch(command: "cmd /c dir \"%userprofile%/My Documents\" > nul")
    }
    
    private static let esyncSettingKey = "EsyncSetting"
    static var esync: Bool {
        get {
            Util.getSetting(settingKey: esyncSettingKey, defaultValue: true)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: esyncSettingKey)
            createCompatToolsInstance(Wine.wineBinURL.path, Wine.debug, Wine.esync)
        }
    }
    
    private static let wineDebugSettingKey = "WineDebugSetting"
    static var debug: String {
        get {
            Util.getSetting(settingKey: wineDebugSettingKey, defaultValue: "-all")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: wineDebugSettingKey)
            createCompatToolsInstance(Wine.wineBinURL.path, Wine.debug, Wine.esync)
        }
    }
    
    static func kill() {
        killWine()
    }
    
    static func addReg(key: String, value: String, data: String) {
        addRegistryKey(key, value, data)
    }
    
    static func override(dll: String, type: String) {
        addReg(key: "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides", value: dll, data: type)
    }
    
    static func set(version: String) {
        launch(command: "winecfg -v \(version)", blocking: true)
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
