//
//  Anamnesis.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 03.07.22.
//

import Foundation
import ZIPFoundation

struct Anamnesis {
    @available(*, unavailable) private init() {}
    
    private static let dir = Wine.prefix.appendingPathComponent("/drive_c/Anamnesis")
    private static let exec = dir.appendingPathComponent("Anamnesis.exe")
    private static let remote = URL(string: "https://github.com/imchillin/Anamnesis/releases/latest/download/Anamnesis.zip")!
    
    static func launch() {
        install()
        Wine.launch(command: "\"\(exec.path)\"", wineD3D: true)
    }
    
    static func install() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: Wine.prefix.appendingPathComponent("/drive_c/Program Files/dotnet/dotnet.exe").path) {
            Dotnet.installDotNet607()
        }
        Dotnet.download(url: remote.absoluteString)
        guard let archive = Archive(url: Util.cache.appendingPathComponent("Anamnesis.zip"), accessMode: .read) else  {
            Log.fatal("Fatal error reading Anamnesis archive")
            return
        }
        Util.make(dir: dir)
        for file in archive {
            try? _ = archive.extract(file, to: dir.appendingPathComponent(file.path))
        }
    }
    
}
