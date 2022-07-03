//
//  Anamnesis.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 03.07.22.
//

import Foundation
import ZIPFoundation

class Anamnesis {
    @available(*, unavailable) private init() {}
    
    private static let dir = Wine.prefix.appendingPathComponent("/drive_c/Anamnesis")
    private static let exec = dir.appendingPathComponent("Anamnesis.exe")
    private static let versionFile = dir.appendingPathComponent("version.txt")
    
    private static let version = "2022-05-31"
    private static let remote = URL(string: "https://github.com/imchillin/Anamnesis/releases/download/v\(version)/\(version).zip")!
    
    static func launch() {
        install()
        Wine.launch(command: "\"\(exec.path)\"", wineD3D: true)
    }
    
    static func install() {
        let fm = FileManager.default
        Dotnet.download(url: remote.absoluteString)
        if let data = try? Data.init(contentsOf: versionFile) {
            let readVersion = String(data: data, encoding: .utf8) ?? ""
            if readVersion != version {
                try? fm.removeItem(at: exec)
            }
        }
        guard let archive = Archive(url: Util.cache.appendingPathComponent("\(version).zip"), accessMode: .read) else  {
            Log.fatal("Fatal error reading Anamnesis archive")
            return
        }
        Util.make(dir: dir)
        for file in archive {
            try? _ = archive.extract(file, to: dir.appendingPathComponent(file.path))
        }
        if fm.fileExists(atPath: versionFile.path) {
            try? fm.removeItem(at: versionFile)
        }
        try? version.write(to: versionFile, atomically: true, encoding: String.Encoding.utf8)
    }
    
}
