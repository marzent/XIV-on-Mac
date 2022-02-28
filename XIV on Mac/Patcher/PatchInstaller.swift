//
//  PatchInstaller.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 26.02.22.
//

import Foundation

class PatchInstaller {
    
    private static let dir = Patch.dir.appendingPathComponent("installer")
    private static let exec = dir.appendingPathComponent("XIVLauncher.PatchInstaller")
    
    static func install(_ patch: Patch) {
        let patchPath = Patch.cache.appendingPathComponent(patch.path).path
        var repo = patch.repo
        let res = Util.launchToString(exec: exec, args: ["install", patchPath, repo.patchURL.path])
        
        repo.ver = patch.version
        if !patch.keep {
            try? FileManager.default.removeItem(atPath: patchPath)
        }
        print(res)
    }
    
    static func update() {
        
    }
}
