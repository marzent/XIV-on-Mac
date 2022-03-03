//
//  ACT.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.02.22.
//

import Foundation
import ZIPFoundation

class ACT {
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
    private static let autoLaunchBHKey = "AutoLaunchBH"
    static var autoLaunchBH: Bool {
        get {
            return Util.getSetting(settingKey: autoLaunchBHKey, defaultValue: false)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: autoLaunchBHKey)
        }
    }
    
    private static let remote = URL(string: "https://github.com/EQAditu/AdvancedCombatTracker/releases/download/3.6.0.275/ACTv3.zip")!
    
    @objc static func launch(_ notif: Notification) {
        if autoLaunch {
            launch()
        }
    }
    
    static func launchBH() {
        let bunnyPath = URL(fileURLWithPath: "/Applications/BunnyHUD.app").path
        if FileManager.default.fileExists(atPath: bunnyPath) {
            Util.launch(exec: URL(string: "file:///usr/bin/open")!, args: [bunnyPath])
        }
        else {
            Util.launch(exec: URL(string: "file:///usr/bin/open")!, args: ["-b", "dezent.BunnyHUD"])
        }
    }
    
    static func launch() {
        install()
        Wine.launch(args: [exec.path])
        if autoLaunchBH {
            DispatchQueue.global().asyncAfter(deadline: .now() + 12.0) {
                launchBH()
            }
        }
    }
    
    static func observe() {
        NotificationCenter.default.addObserver(self,selector: #selector(launch(_:)),name: .gameStarted, object: nil)
    }
    
    static func install() {
        Dotnet.download(url: remote.absoluteString)
        guard let archive = Archive(url: Util.cache.appendingPathComponent("ACTv3.zip"), accessMode: .read) else  {
            print("Fatal error reading ACT archive\n", to: &Util.logger)
            return
        }
        Util.make(dir: dir)
        for file in archive {
            try? _ = archive.extract(file, to: dir.appendingPathComponent(file.path))
        }
    }
    
}
