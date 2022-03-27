//
//  FFXIVApp.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 17.03.22.
//

import Foundation

public struct FFXIVApp {
    typealias settings = FFXIVSettings
    let bootRepoURL, bootExeURL, bootExe64URL, launcherExeURL, launcherExe64URL, updaterExeURL, updaterExe64URL: URL
    let gameRepoURL, dx9URL, dx11URL, sqpackFolderURL: URL
    private let bootFiles: [URL]
    
    init() {
        bootRepoURL = FFXIVSettings.gamePath.appendingPathComponent("boot")
        bootExeURL = bootRepoURL.appendingPathComponent("ffxivboot.exe")
        bootExe64URL = bootRepoURL.appendingPathComponent("ffxivboot64.exe")
        launcherExeURL = bootRepoURL.appendingPathComponent("ffxivlauncher.exe")
        launcherExe64URL = bootRepoURL.appendingPathComponent("ffxivlauncher64.exe")
        updaterExeURL = bootRepoURL.appendingPathComponent("ffxivupdater.exe")
        updaterExe64URL = bootRepoURL.appendingPathComponent("ffxivupdater64.exe")
        
        gameRepoURL = FFXIVSettings.gamePath.appendingPathComponent("game")
        dx9URL = gameRepoURL.appendingPathComponent("ffxiv.exe")
        dx11URL = gameRepoURL.appendingPathComponent("ffxiv_dx11.exe")
        sqpackFolderURL = gameRepoURL.appendingPathComponent("sqpack")
        
        bootFiles = [bootExeURL, bootExe64URL, launcherExeURL, launcherExe64URL, updaterExeURL, updaterExe64URL]
    }
    
    func start(sid: String) {
        let baseArgs = [
            ("/DEV.DataPathType", "1"),
            ("/DEV.MaxEntitledExpansionID", "\(settings.expansionId.rawValue)"),
            ("/DEV.TestSID", sid),
            ("/DEV.UseSqPack", "1"),
            ("/SYS.Region", "\(settings.region.rawValue)"),
            ("/language", "\(settings.language.rawValue)"),
            ("/IsSteam", settings.platform == .steam ? "1" : "0"),
            ("/ver", FFXIVRepo.game.ver)
        ]
        let args = [dx11URL.path, FFXIVApp.encryptedArgs(args: baseArgs)]
        DXVK.install()
        if settings.dalamud {
            Dalamud.launch(args: args, language: settings.language, gameVersion: FFXIVRepo.game.ver)
        }
        else {
            NotificationCenter.default.post(name: .loginInfo, object: nil, userInfo: [Notification.status.info: "Starting Wine"])
            Wine.launch(args: args)
        }
        let maxGameStartTime = 15.0
        DispatchQueue.main.asyncAfter(deadline: .now() + maxGameStartTime) {
            NotificationCenter.default.post(name: .gameStarted, object: nil)
        }
    }
    
    static var running: Bool {
        Wine.pidOf(processName: "ffxiv_dx11.exe") > 0
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
    
    var bootHash: String {
        bootFiles.map({(try? FFXIVApp.hashSegment(file: $0)) ?? ""}).joined(separator: ",")
    }

    func versionList(maxEx: UInt32) -> String {
        let expansions = FFXIVRepo.expansions(max: maxEx).map({"\($0.rawValue)\t\($0.ver)"})
        return "\(FFXIVRepo.boot.ver)=\(bootHash)\n\(expansions.joined(separator: "\n"))"
    }
    
    private static func hashSegment(file: URL) throws -> String {
        let (hash, len) = try Encryption.sha1(file: file)
        return "\(file.lastPathComponent)/\(len)/\(hash)"
    }
    
}
