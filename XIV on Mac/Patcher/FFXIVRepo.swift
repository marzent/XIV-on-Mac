//
//  FFXIVRepo.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 28.02.22.
//

import Foundation

fileprivate let baseVer = "2012.01.01.0000.0000"

public enum FFXIVRepo: String {
    case boot = "ffxivboot"
    case game = "ffxivgame"
    case ex1 = "ex1"
    case ex2 = "ex2"
    case ex3 = "ex3"
    case ex4 = "ex4"
    
    var ver: String {
        get {
            read(from: verURL)
        }
        set {
            write(to: verURL, content: newValue)
        }
    }
    
    var bck: String {
        get {
            read(from: bckURL)
        }
        set {
            write(to: bckURL, content: newValue)
        }
    }
    
    private func read(from: URL) -> String {
        if let data = try? Data.init(contentsOf: from) {
            let readVer = String(data: data, encoding: .utf8) ?? ""
            return readVer.isEmpty ? baseVer : readVer
        }
        return baseVer
    }
    
    private func write(to: URL, content: String) {
        Util.make(dir: baseURL)
        let fm = FileManager.default
        let file = to
        do {
            if fm.fileExists(atPath: file.path) {
                try fm.removeItem(atPath: file.path)
            }
            try content.write(to: file, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Error writing version/bck file \(to)\n", to: &Util.logger)
        }
    }
    
    static func array(_ maxExpansion: UInt32) -> [FFXIVRepo] {
        return [.boot, .game, .ex1, .ex2, .ex3, .ex4].dropLast(4 - Int(maxExpansion))
    }
    
    var baseURL: URL {
        let app = FFXIVApp()
        switch self {
        case .boot:
            return app.bootRepoURL
        case .game:
            return app.gameRepoURL
        default:
            return app.sqpackFolderURL.appendingPathComponent(self.rawValue)
        }
    }
    
    var patchURL: URL {
        let app = FFXIVApp()
        switch self {
        case .boot:
            return app.bootRepoURL
        default:
            return app.gameRepoURL
        }
    }
    
    var verURL: URL {
        baseURL.appendingPathComponent(self.rawValue + ".ver")
    }
    
    var bckURL: URL {
        baseURL.appendingPathComponent(self.rawValue + ".bck")
    }

}
