//
//  Settings.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 19.02.22.
//

import Foundation
import XIVLauncher

public enum Settings {
    private static let storage = UserDefaults.standard
    
    static func syncToXL() {
        let gamePathCString = FileManager.default.fileSystemRepresentation(withPath: gamePath.path)
        let gameConfigPathCString = FileManager.default.fileSystemRepresentation(withPath: gameConfigPath.path)
        let patchDirCString = FileManager.default.fileSystemRepresentation(withPath: Patch.dir.path)
        let loadMethod: Dalamud.LoadMethod = dalamudEnabled ? (dalamudEntryPoint ? .entryPoint : .dllInject) : .ACLonly
        let delayMs = dalamudEntryPoint ? 0 : Int32(injectionDelay * 1000)
        loadConfig(acceptLanguage, gamePathCString, gameConfigPathCString, language.rawValue, encryptedArguments, freeTrial, platform.rawValue, patchDirCString, 0, 0, loadMethod.rawValue, delayMs, autoLogin, Wine.retina)
    }
    
    private static let platformKey = "Platform"
    static var platform: FFXIVPlatform {
        get {
            FFXIVPlatform(rawValue: Util.getSetting(settingKey: platformKey, defaultValue: FFXIVPlatform.mac.rawValue)) ?? .mac
        }
        set {
            storage.set(newValue.rawValue, forKey: platformKey)
            syncToXL()
            Wine.addReg(key: "HKEY_CURRENT_USER\\Software\\Wine", value: "HideWineExports", data: newValue == .mac ? "0" : "1")
        }
    }
    
    private static let gamePathKey = "GamePath"
    static let defaultGameLoc = Util.applicationSupport.appendingPathComponent("ffxiv")
    static var gamePath: URL {
        get {
            URL(fileURLWithPath: Util.getSetting(settingKey: gamePathKey, defaultValue: defaultGameLoc.path))
        }
        set {
            storage.set(newValue.path, forKey: gamePathKey)
            syncToXL()
        }
    }
    
    static func setDefaultGamepath() {
        storage.removeObject(forKey: gamePathKey)
        syncToXL()
    }
    
    private static let gameConfigPathKey = "GameConfigPath"
    static let defaultGameConfigLoc = Util.applicationSupport.appendingPathComponent("ffxivConfig")
    static var gameConfigPath: URL {
        get {
            URL(fileURLWithPath: Util.getSetting(settingKey: gameConfigPathKey, defaultValue: defaultGameConfigLoc.path))
        }
        set {
            storage.set(newValue.path, forKey: gameConfigPathKey)
            syncToXL()
        }
    }
    
    private static let usernameKey = "Username"
    private static var credentialsCache: LoginCredentials?
    static var credentials: LoginCredentials? {
        get {
            if let creds = credentialsCache {
                return creds
            }
            if let storedUsername = storage.string(forKey: usernameKey) {
                return LoginCredentials.storedLogin(username: storedUsername)
            }
            return nil
        }
        set {
            if let creds = newValue {
                storage.set(creds.username, forKey: usernameKey)
                creds.saveLogin()
                credentialsCache = creds
            }
        }
    }
    
    private static let freeTrialKey = "FreeTrial"
    static var freeTrial: Bool {
        get {
            storage.bool(forKey: freeTrialKey)
        }
        set {
            storage.set(newValue, forKey: freeTrialKey)
            syncToXL()
        }
    }
    
    private static let verboseLoggingKey = "VerboseLogging"
    static var verboseLogging: Bool {
        get {
        #if DEBUG
            true
        #else
            storage.bool(forKey: verboseLoggingKey)
        #endif
        }
        set {
            storage.set(newValue, forKey: verboseLoggingKey)
        }
    }
    
    private static let exitWithGameKey = "ExitWithGame"
    static var exitWithGame: Bool {
        get {
            Util.getSetting(settingKey: exitWithGameKey, defaultValue: true)
        }
        set {
            storage.set(newValue, forKey: exitWithGameKey)
        }
    }
    
    private static let nonZeroExitErrorKey = "NonZeroExitError"
    static var nonZeroExitError: Bool {
        get {
            Util.getSetting(settingKey: nonZeroExitErrorKey, defaultValue: true)
        }
        set {
            storage.set(newValue, forKey: nonZeroExitErrorKey)
        }
    }
    
    private static let usesOneTimePasswordKey = "UsesOneTimePassword"
    static var usesOneTimePassword: Bool {
        get {
            storage.bool(forKey: usesOneTimePasswordKey)
        }
        set {
            storage.set(newValue, forKey: usesOneTimePasswordKey)
        }
    }
    
    private static let autoLoginKey = "AutoLogin"
    static var autoLogin: Bool {
        get {
            storage.bool(forKey: autoLoginKey)
        }
        set {
            storage.set(newValue, forKey: autoLoginKey)
        }
    }
    
    private static let acceptLanguageKey = "AcceptLanguage"
    static var acceptLanguage: String {
        guard let storedAcceptLanguage = storage.object(forKey: acceptLanguageKey) else {
            let seed = Int32.random(in: 0 ..< 420)
            let newAcceptLaungage = String(cString: generateAcceptLanguage(seed)!)
            storage.set(newAcceptLaungage, forKey: acceptLanguageKey)
            return newAcceptLaungage
        }
        return storedAcceptLanguage as! String
    }
    
    private static let languageKey = "Language"
    static var language: FFXIVLanguage {
        get {
            let guess = FFXIVLanguage.guessFromLocale()
            let stored = UInt8(Util.getSetting(settingKey: languageKey, defaultValue: guess.rawValue))
            return FFXIVLanguage(rawValue: stored) ?? guess
        }
        set {
            storage.set(newValue.rawValue, forKey: languageKey)
            syncToXL()
        }
    }
    
    private static let encryptedArgumentsKey = "EncryptedArguments"
    static var encryptedArguments: Bool {
        get {
            Util.getSetting(settingKey: encryptedArgumentsKey, defaultValue: true)
        }
        set {
            storage.set(newValue, forKey: encryptedArgumentsKey)
            syncToXL()
        }
    }
    
    private static let dalamudSettingsKey = "DalamudEnabled"
    static var dalamudEnabled: Bool {
        get {
            storage.bool(forKey: dalamudSettingsKey)
        }
        set {
            storage.set(newValue, forKey: dalamudSettingsKey)
            syncToXL()
        }
    }
    
    private static let dalamudEntryPointSettingsKey = "DalamudEntrypoint"
    static var dalamudEntryPoint: Bool {
        get {
            Util.getSetting(settingKey: dalamudEntryPointSettingsKey, defaultValue: false)
        }
        set {
            storage.set(newValue, forKey: dalamudEntryPointSettingsKey)
            syncToXL()
        }
    }
    
    public static let defaultInjectionDelay = 4.0
    private static let injectionSettingKey = "InjectionDelaySetting"
    static var injectionDelay: Double {
        get {
            return Util.getSetting(settingKey: injectionSettingKey, defaultValue: defaultInjectionDelay)
        }
        set {
            storage.set(newValue, forKey: injectionSettingKey)
            syncToXL()
        }
    }
    
    public static let defaultMetal3PerformanceOverlay: Bool = false
    private static let metal3PerformanceOverlayKey = "Metal3PerformanceOverlayEnabled"
    static var metal3PerformanceOverlay: Bool {
        get {
            guard #available(macOS 13.0, *) else {
                // Metal 3 is a macOS 13 feature
                return false
            }
            return Util.getSetting(settingKey: metal3PerformanceOverlayKey, defaultValue: defaultMetal3PerformanceOverlay)
        }
        set {
            storage.set(newValue, forKey: metal3PerformanceOverlayKey)
            Wine.setup()
        }
    }
    
    private static let dxmtSettingsKey = "DxmtEnabled"
    static var dxmtEnabled: Bool {
        get {
            guard #available(macOS 14.0, *) else {
                // DXMT requires Metal 3.1 features
                return false
            }
            return Util.getSetting(settingKey: dxmtSettingsKey, defaultValue: false)
        }
        set {
            storage.set(newValue, forKey: dxmtSettingsKey)
        }
    }
    
    private static let metalFxSpatialSettingsKey = "MetalFxSpatialEnabled"
    static var metalFxSpatialEnabled: Bool {
        get {
            Util.getSetting(settingKey: metalFxSpatialSettingsKey, defaultValue: false)
        }
        set {
            storage.set(newValue, forKey: metalFxSpatialSettingsKey)
            Wine.setup()
        }
    }
    
    private static let metalFxSpatialFactorSettingsKey = "MetalFxSpatialFactor"
    static var metalFxSpatialFactor: Float {
        get {
            Util.getSetting(settingKey: metalFxSpatialFactorSettingsKey, defaultValue: 2.0)
        }
        set {
            storage.set(newValue, forKey: metalFxSpatialFactorSettingsKey)
            Wine.setup()
        }
    }
    
    private static let maxFramerateSettingsKey = "MaxFramerate"
    static var maxFramerate: UInt32 {
        get {
            Util.getSetting(settingKey: maxFramerateSettingsKey, defaultValue: UInt32(Dxvk.options.maxFramerate))
        }
        set {
            storage.set(newValue, forKey: maxFramerateSettingsKey)
            Wine.setup()
        }
    }
}
