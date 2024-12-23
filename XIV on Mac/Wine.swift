//
//  Wine.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 01.02.22.
//

import CompatibilityTools
import Foundation

enum Wine {
    static let wineBinURL = Bundle.main.url(
        forResource: "bin", withExtension: nil, subdirectory: "wine")!
    static let wineDllURL = Bundle.main.url(
        forResource: "lib/wine", withExtension: nil, subdirectory: "wine")!
    static let prefix = Util.applicationSupport.appendingPathComponent(
        "wineprefix")

    @MainActor static func setup() {
        addEnvironmentVariable(
            "WINEDLLPATH",
            FileManager.default.fileSystemRepresentation(
                withPath: wineDllURL.path))
        addEnvironmentVariable("WINEMSYNC", msync ? "1" : "0")
        addEnvironmentVariable(
            "DXMT_CONFIG",
            "d3d11.metalSpatialUpscaleFactor=\(Settings.metalFxSpatialFactor);d3d11.preferredMaxFrameRate=\(Settings.maxFramerate);"
        )
        addEnvironmentVariable(
            "DXMT_METALFX_SPATIAL_SWAPCHAIN",
            Settings.metalFxSpatialEnabled ? "1" : "0")
        addEnvironmentVariable("LANG", "en_US")
        addEnvironmentVariable("MVK_ALLOW_METAL_FENCES", "1")  // XXX Required by DXVK for Apple/NVidia GPUs (better FPS than CPU Emulation)
        addEnvironmentVariable("MVK_CONFIG_FULL_IMAGE_VIEW_SWIZZLE", "1")  // XXX Required by DXVK for Intel/NVidia GPUs
        addEnvironmentVariable("MVK_CONFIG_RESUME_LOST_DEVICE", "1")  // XXX Required by WINE (doesn't handle VK_ERROR_DEVICE_LOST correctly)
        addEnvironmentVariable("DXVK_HUD", Dxvk.options.getHud())
        addEnvironmentVariable("DXVK_ASYNC", Dxvk.options.getAsync())
        addEnvironmentVariable("DXVK_FRAME_RATE", String(Settings.maxFramerate))
        addEnvironmentVariable("DXVK_CONFIG_FILE", "C:\\dxvk.conf")
        addEnvironmentVariable("DXVK_STATE_CACHE_PATH", "C:\\")
        addEnvironmentVariable("DXVK_LOG_PATH", "C:\\")
        addEnvironmentVariable("DOTNET_EnableWriteXorExecute", "0")  // XXX Required for Apple Silicon and .NET 7+
        addEnvironmentVariable(
            "MTL_HUD_ENABLED", Settings.metal3PerformanceOverlay ? "1" : "0")
        createCompatToolsInstance(
            FileManager.default.fileSystemRepresentation(
                withPath: wineBinURL.path), debug, esync)
    }

    static func boot() {
        DispatchQueue.global(qos: .utility).async {
            ensurePrefix()
        }
    }

    static func launch(
        command: String, blocking: Bool = false, wineD3D: Bool = false
    ) {
        runInPrefix(command, blocking, wineD3D)
    }

    static func pidOf(processName: String) -> Int {
        pidsOf(processName: processName).first ?? 0
    }

    static func pidsOf(processName: String) -> [Int] {
        Array(
            String(cString: getProcessIds(processName)).split(separator: " ")
                .compactMap { Int($0) })
    }

    static func convertToUnixPidFrom(winePid: Int) -> pid_t {
        getUnixProcessId(Int32(winePid))
    }

    static func running(processName: String) -> Bool {
        pidsOf(processName: processName).count > 0
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
            createCompatToolsInstance(
                FileManager.default.fileSystemRepresentation(
                    withPath: wineBinURL.path), debug, esync)
        }
    }

    private static let msyncSettingKey = "MsyncSetting"
    static var msync: Bool {
        get {
            Util.getSetting(settingKey: msyncSettingKey, defaultValue: true)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: msyncSettingKey)
            addEnvironmentVariable("WINEMSYNC", msync ? "1" : "0")
        }
    }

    private static let wineDebugSettingKey = "WineDebugSetting"
    static var debug: String {
        get {
            Util.getSetting(
                settingKey: wineDebugSettingKey, defaultValue: "-all")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: wineDebugSettingKey)
            createCompatToolsInstance(
                FileManager.default.fileSystemRepresentation(
                    withPath: wineBinURL.path), debug, esync)
        }
    }

    static func kill() {
        killWine()
    }

    static func addReg(key: String, value: String, data: String) {
        addRegistryKey(key, value, data)
    }

    static func override(dll: String, type: String) {
        addReg(
            key: "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides", value: dll,
            data: type)
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
            addReg(
                key: "HKEY_CURRENT_USER\\Software\\Wine\\Mac Driver",
                value: "RetinaMode", data: _retina ? "y" : "n")
            UserDefaults.standard.set(_retina, forKey: retinaSettingKey)
        }
    }

    private static let leftOptionIsAltSettingKey = "LeftOptionIsAlt"
    static var leftOptionIsAlt: Bool {
        get {
            Util.getSetting(
                settingKey: leftOptionIsAltSettingKey, defaultValue: true)
        }
        set(_leftOpenIsAlt) {
            addReg(
                key: "HKEY_CURRENT_USER\\Software\\Wine\\Mac Driver",
                value: "LeftOptionIsAlt", data: _leftOpenIsAlt ? "y" : "n")
            UserDefaults.standard.set(
                _leftOpenIsAlt, forKey: leftOptionIsAltSettingKey)
        }
    }

    private static let rightOptionIsAltSettingKey = "RightOptionIsAlt"
    static var rightOptionIsAlt: Bool {
        get {
            Util.getSetting(
                settingKey: rightOptionIsAltSettingKey, defaultValue: true)
        }
        set(_rightOpenIsAlt) {
            addReg(
                key: "HKEY_CURRENT_USER\\Software\\Wine\\Mac Driver",
                value: "RightOptionIsAlt", data: _rightOpenIsAlt ? "y" : "n")
            UserDefaults.standard.set(
                _rightOpenIsAlt, forKey: rightOptionIsAltSettingKey)
        }
    }

    private static let leftCommandIsCtrlSettingKey = "LeftCommandIsCtrl"
    static var leftCommandIsCtrl: Bool {
        get {
            Util.getSetting(
                settingKey: leftCommandIsCtrlSettingKey, defaultValue: true)
        }
        set(_leftCommandIsCtrl) {
            addReg(
                key: "HKEY_CURRENT_USER\\Software\\Wine\\Mac Driver",
                value: "LeftCommandIsCtrl", data: _leftCommandIsCtrl ? "y" : "n"
            )
            UserDefaults.standard.set(
                _leftCommandIsCtrl, forKey: leftCommandIsCtrlSettingKey)
        }
    }

    private static let rightCommandIsCtrlSettingKey = "RightCommandIsCtrl"
    static var rightCommandIsCtrl: Bool {
        get {
            Util.getSetting(
                settingKey: rightCommandIsCtrlSettingKey, defaultValue: true)
        }
        set(_rightCommandIsCtrl) {
            addReg(
                key: "HKEY_CURRENT_USER\\Software\\Wine\\Mac Driver",
                value: "RightCommandIsCtrl",
                data: _rightCommandIsCtrl ? "y" : "n")
            UserDefaults.standard.set(
                _rightCommandIsCtrl, forKey: rightCommandIsCtrlSettingKey)
        }
    }
}
