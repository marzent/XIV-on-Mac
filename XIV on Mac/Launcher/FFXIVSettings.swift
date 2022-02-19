//
//  FFXIVSettings.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 19.02.22.
//

import Foundation

public struct FFXIVSettings {
    private static let storage = UserDefaults.standard
    
    private static let platformKey = "Platform"
    static var platform: FFXIVPlatform {
        get {
            return FFXIVPlatform(rawValue: UInt32(storage.integer(forKey: platformKey))) ?? .mac
        }
        set {
            storage.set(newValue.rawValue, forKey: platformKey)
            Wine.addReg(key: "HKEY_CURRENT_USER\\Software\\Wine", value: "HideWineExports", data: newValue == .mac ? "0" : "1")
        }
    }
    
    private static let gamePathKey = "GamePath"
    static var gamePath: URL {
        get {
            return URL(fileURLWithPath: Util.getSetting(settingKey: gamePathKey, defaultValue: Wine.prefix.appendingPathComponent("drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn").path))
        }
        set {
            storage.set(newValue.path, forKey: gamePathKey)
        }
    }
    
    private static let usernameKey = "Username"
    private static var credentialsCache: FFXIVLoginCredentials?
    static var credentials: FFXIVLoginCredentials? {
        get {
            if let creds = credentialsCache {
                return creds
            }
            if let storedUsername = storage.string(forKey: usernameKey) {
                return FFXIVLoginCredentials.storedLogin(username: storedUsername)
            }
            return nil
        }
        set {
            if let username = newValue?.username {
                storage.set(username, forKey: usernameKey)
            }
            if let creds = newValue {
                creds.saveLogin()
                credentialsCache = creds
            }
        }
    }
    
    private static let expansionIdKey = "ExpansionId"
    static var expansionId: FFXIVExpansionLevel {
        get {
            return FFXIVExpansionLevel(rawValue: UInt32(storage.integer(forKey: expansionIdKey))) ?? .aRealmReborn
        }
        set {
            storage.set(newValue.rawValue, forKey: expansionIdKey)
        }
    }
    
    private static let dalamudKey = "DalamudEnabled"
    static var dalamud: Bool {
        get {
            return storage.bool(forKey: dalamudKey)
        }
        set {
            storage.set(newValue, forKey: dalamudKey)
        }
    }
    
    private static let usesOneTimePasswordKey = "UsesOneTimePassword"
    static var usesOneTimePassword: Bool {
        get {
            return storage.bool(forKey: usesOneTimePasswordKey)
        }
        set {
            storage.set(newValue, forKey: usesOneTimePasswordKey)
        }
    }
    
    private static let regionKey = "Region"
    static var region: FFXIVRegion {
        get {
            FFXIVRegion(rawValue: UInt32(storage.integer(forKey: regionKey))) ?? FFXIVRegion.guessFromLocale()
        }
        set {
            storage.set(newValue.rawValue, forKey: regionKey)
        }
    }
    
    private static let languageKey = "Language"
    static var language: FFXIVLanguage {
        get {
            FFXIVLanguage(rawValue: UInt32(storage.integer(forKey: languageKey))) ?? region.language
        }
        set {
            storage.set(newValue.rawValue, forKey: languageKey)
        }
    }
    
}
