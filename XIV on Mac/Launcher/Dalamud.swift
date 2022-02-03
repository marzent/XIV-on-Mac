//
//  Dalamud.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 03.02.22.
//

import Foundation
import ZIPFoundation

struct Dalamud {
    @available(*, unavailable) private init() {}
    
    struct nativeLauncher {
        static let exec = "NativeLauncher.exe"
        static let path = Wine.xomData.appendingPathComponent(exec).path
        static let remote = "https://github.com/redstrate/nativelauncher/releases/download/v1.0.0/" + exec
    }
    
    static let path = Wine.xomData.appendingPathComponent("Dalamud")
    static let remote = "https://goatcorp.github.io/dalamud-distrib/latest.zip"

    static func install() {
        Setup.download(url: remote)
        Setup.download(url: nativeLauncher.remote)
        let fm = FileManager.default
        try? fm.copyItem(atPath: Util.cache.appendingPathComponent(nativeLauncher.exec).path, toPath: nativeLauncher.path)
        try? fm.unzipItem(at: Util.cache.appendingPathComponent("latest.zip"), to: path)
    }
    
    static func launch(args: [String]) {
        let output = Util.launchToString(exec: Wine.wine64, args: [nativeLauncher.path] + args)
        let pid = String(output.split(separator: "\n").last!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
            Wine.launch(args: [path.appendingPathComponent("Dalamud.Injector.exe").path, pid])
        }
    }
    
}
