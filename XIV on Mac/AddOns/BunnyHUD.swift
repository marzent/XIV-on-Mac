//
//  BunnyHUD.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 15.07.22.
//

import Foundation
import ZIPFoundation

struct BunnyHUD {
    @available(*, unavailable) private init() {}
    
    private static let autoLaunchBHKey = "AutoLaunchBH"
    static var autoLaunch: Bool {
        get {
            return Util.getSetting(settingKey: autoLaunchBHKey, defaultValue: false)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: autoLaunchBHKey)
        }
    }
    
    static func launch() {
        let bunnyPath = URL(fileURLWithPath: "/Applications/BunnyHUD.app").path
        if FileManager.default.fileExists(atPath: bunnyPath) {
            Util.launch(exec: URL(string: "file:///usr/bin/open")!, args: [bunnyPath])
        }
        else {
            Util.launch(exec: URL(string: "file:///usr/bin/open")!, args: ["-b", "dezent.BunnyHUD"])
        }
    }
    
}
