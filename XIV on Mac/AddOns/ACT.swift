//
//  ACT.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.02.22.
//

import Foundation
import ZIPFoundation

struct ACT {
    @available(*, unavailable) private init() {}
    
    private static let dir = Wine.prefix.appendingPathComponent("/drive_c/Program Files (x86)/Advanced Combat Tracker")
    private static let exec = dir.appendingPathComponent("Advanced Combat Tracker.exe")
    
    private static let autoLaunchACTKey = "AutoLaunchACT"
    static var autoLaunch: Bool {
        get {
            return Util.getSetting(settingKey: autoLaunchACTKey, defaultValue: false)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: autoLaunchACTKey)
        }
    }
    
    private static let remote = URL(string: "https://github.com/EQAditu/AdvancedCombatTracker/releases/download/3.6.0.275/ACTv3.zip")!
    
    static func launchNotify() {
        if autoLaunch {
            launch()
        }
    }

    static func launch() {
        install()
        Wine.launch(command: "\"\(exec.path)\"")
        if BunnyHUD.autoLaunch {
            DispatchQueue.global().asyncAfter(deadline: .now() + 12.0) {
                BunnyHUD.launch()
            }
        }
    }
    
    static func install() {
        Dotnet.download(url: remote.absoluteString)
        guard let archive = Archive(url: Util.cache.appendingPathComponent("ACTv3.zip"), accessMode: .read) else {
            Log.fatal("Fatal error reading ACT archive")
            return
        }
        Util.make(dir: dir)
        for file in archive {
            try? _ = archive.extract(file, to: dir.appendingPathComponent(file.path))
        }
    }
}
