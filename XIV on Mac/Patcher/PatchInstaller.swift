//
//  PatchInstaller.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 26.02.22.
//

import AppKit
import Embassy
import OrderedCollections
import SeeURL

class PatchInstaller {
    
    private static let dir = Patch.dir.appendingPathComponent("XIVLauncher.PatchInstaller.app/Contents/Resources")
    private static let exec = dir.appendingPathComponent("XIVLauncher.PatchInstaller")
    private static let remoteURL = URL(string: "https://www.xivmac.com/sites/default/files/seventh_dawn")!
    
    static func install(_ patch: Patch) {
        let patchPath = Patch.cache.appendingPathComponent(patch.path).path
        var repo = patch.repo
        let res = Util.launchToString(exec: exec, args: ["install", patchPath, repo.patchURL.path])
        print(res)
        if res.suffix(9) == " INF] OK\n" {
            repo.ver = patch.version
            print("Updated ver to \(repo.ver) \n")
        }
        else {
            DispatchQueue.main.sync {
                let alert = NSAlert()
                alert.addButton(withTitle: "Close")
                alert.alertStyle = .critical
                alert.messageText = "XIVLancher.PatchInstaller Error"
                alert.informativeText = res
                alert.runModal()
                Util.quit()
            }
        }
        if !Patch.keep {
            try? FileManager.default.removeItem(atPath: patchPath)
        }
    }
    
    static func update() {
        let fm = FileManager.default
        if needsUpdate {
            try? fm.removeItem(at: Util.cache.appendingPathComponent("PatchInstaller.zip"))
            try? fm.removeItem(at: Patch.dir.appendingPathComponent("XIVLauncher.PatchInstaller.app"))
        }
        try? HTTPClient.fetchFile(url: remoteURL.appendingPathComponent("PatchInstaller.zip"))
        try? fm.unzipItem(at: Util.cache.appendingPathComponent("PatchInstaller.zip"), to: Patch.dir)
        try? fm.removeItem(at: Patch.dir.appendingPathComponent("__MACOSX"))
    }
    
    private static var needsUpdate: Bool {
        do {
            let deps = try String(contentsOf: dir.appendingPathComponent("XIVLauncher.PatchInstaller.deps.json"), encoding: .utf8)
            let head = String(deps.prefix(300))
            var remoteVersion: String?
            let semaphore = DispatchSemaphore(value: 0)
            let task = URLSession.shared.downloadTask(with: remoteURL.appendingPathComponent("version.txt")) { localURL, urlResponse, error in
                if let localURL = localURL {
                    remoteVersion = try? String(String(contentsOf: localURL).dropLast())
                }
                semaphore.signal()
            }
            task.resume()
            semaphore.wait()
            if let range = head.range(of: #"(?<=XIVLauncher.PatchInstaller\/).*(?=":)"#, options: .regularExpression) {
                let localVersion = head[range]
                if let remoteVersion = remoteVersion {
                    return localVersion != remoteVersion
                }
                return false
            }
            return true
        }
        catch {
            return true
        }
    }
}
