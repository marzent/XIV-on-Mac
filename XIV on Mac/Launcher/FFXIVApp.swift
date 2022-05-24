//
//  FFXIVApp.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 17.03.22.
//

import Foundation

public struct FFXIVApp {
    typealias settings = Settings
    static let configFolder = Util.userHome.appendingPathComponent("/Documents/My Games/FINAL FANTASY XIV - A Realm Reborn/")
    static let configURL = configFolder.appendingPathComponent("FFXIV.cfg")
    let bootRepoURL, bootExeURL, bootExe64URL, launcherExeURL, launcherExe64URL, updaterExeURL, updaterExe64URL: URL
    let gameRepoURL, dx9URL, dx11URL, sqpackFolderURL: URL
    private let bootFiles: [URL]
    
    init() {
        bootRepoURL = Settings.gamePath.appendingPathComponent("boot")
        bootExeURL = bootRepoURL.appendingPathComponent("ffxivboot.exe")
        bootExe64URL = bootRepoURL.appendingPathComponent("ffxivboot64.exe")
        launcherExeURL = bootRepoURL.appendingPathComponent("ffxivlauncher.exe")
        launcherExe64URL = bootRepoURL.appendingPathComponent("ffxivlauncher64.exe")
        updaterExeURL = bootRepoURL.appendingPathComponent("ffxivupdater.exe")
        updaterExe64URL = bootRepoURL.appendingPathComponent("ffxivupdater64.exe")
        
        gameRepoURL = Settings.gamePath.appendingPathComponent("game")
        dx9URL = gameRepoURL.appendingPathComponent("ffxiv.exe")
        dx11URL = gameRepoURL.appendingPathComponent("ffxiv_dx11.exe")
        sqpackFolderURL = gameRepoURL.appendingPathComponent("sqpack")
        
        bootFiles = [bootExeURL, bootExe64URL, launcherExeURL, launcherExe64URL, updaterExeURL, updaterExe64URL]
    }
    
//    func startOfficialLauncher() {
//        Wine.launch(args: [bootExe64URL.path])
//    }
    
    static var running: Bool {
        instances > 0
    }
    
    static var instances: Int {
        Wine.pidsOf(processName: "ffxiv_dx11.exe").count
    }

    private static func doubleSpaceify(_ str: String) -> String {
        return str.replacingOccurrences(of: " ", with: "  ")
    }

    private static func checksum(key: UInt64) -> String {
        let checksumTable = [
            "f", "X", "1", "p", "G", "t", "d", "S",
            "5", "C", "A", "P", "4", "_", "V", "L"
        ]
        let index = Int((key & 0x000F0000) >> 16)
        return checksumTable[index]
    }
    
    private static func encryptedArgs(args: [(String, String)]) -> String {
        let maskedTicks = Wine.tickCount & 0xFFFFFFFF
        let key = maskedTicks & 0xFFFF0000
        let check = checksum(key: key)
        let keyStr = String(format: "%08x", key)
        let argStr = args.reduce(into: "") { (result, tuple) in
            let (key, value) = tuple
            result += " \(doubleSpaceify(key)) =\(doubleSpaceify(value))"
        }
        let cipher = Encryption.blowfish(key: keyStr, toEncrypt: [UInt8](argStr.utf8), broken: true)
        let cipherText = Data(cipher).squareBase64EncodedString()
        return "//**sqex0003\(cipherText)\(check)**//"
    }
    
    var installed: Bool {
        bootFiles.allSatisfy({FileManager.default.fileExists(atPath: $0.path)})
    }
}
