//
//  StartGame.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Cocoa
import CryptoSwift


class StartGameOperation: AsyncOperation {
    typealias settings = FFXIVSettings
    let sid: String
    
    init(sid: String) {
        self.sid = sid
        super.init()
    }
    
    override func main() {
        let args = arguments(app: FFXIVApp())
        if settings.dalamud {
            Dalamud.launch(args: args, language: settings.language, gameVersion: FFXIVRepo.game.ver)
        }
        else {
            NotificationCenter.default.post(name: .loginInfo, object: nil, userInfo: [Notification.status.info: "Starting Wine"])
            Wine.launch(args: args)
        }
        state = .finished
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            NotificationCenter.default.post(name: .gameStarted, object: nil)
        }
    }
    
    class func vanilla() {
        let app = FFXIVApp()
        Wine.launch(args: [app.bootExe64URL.path])
    }
    
    class func blowfishKey(ticks: UInt64) -> UInt64 {
        let maskedTicks = ticks & 0xFFFFFFFF
        let key = maskedTicks & 0xFFFF0000
        return key
    }

    class func doubleSpaceify(_ str: String) -> String {
        return str.replacingOccurrences(of: " ", with: "  ")
    }

    class func checksum(key: UInt64) -> String {
        let checksumTable = [
            "f", "X", "1", "p", "G", "t", "d", "S",
            "5", "C", "A", "P", "4", "_", "V", "L"
        ]
        let index = Int((key & 0x000F0000) >> 16)
        return checksumTable[index]
    }

    class func encryptedArgs(args: [(String, String)], ticks: UInt64) -> String {
        let key = blowfishKey(ticks: ticks)
        let check = checksum(key: key)
        let keyStr = String(format: "%08x", key)
        let keyBytes = [UInt8](keyStr.utf8)
        let argStr = args.reduce(into: "") { (result, tuple) in
            let (key, value) = tuple
            result += " \(doubleSpaceify(key)) =\(doubleSpaceify(value))"
        }
        let bigEndianBytes = Util.swapByteOrder32(Util.zeroPad(array: [UInt8](argStr.utf8)))
        let cipherBytes = try! Blowfish(key: keyBytes, blockMode: ECB(), padding: .zeroPadding).encrypt(bigEndianBytes)
        let cipherText = Data(Util.swapByteOrder32(cipherBytes)).squareBase64EncodedString()
        return "//**sqex0003\(cipherText)\(check)**//"
    }
    
    func arguments(app: FFXIVApp) -> [String] {
        let ticks = Wine.tickCount
        let args = [
            ("/DEV.DataPathType", "1"),
            ("/DEV.MaxEntitledExpansionID", "\(settings.expansionId.rawValue)"),
            ("/DEV.TestSID", sid),
            ("/DEV.UseSqPack", "1"),
            ("/SYS.Region", "\(settings.region.rawValue)"),
            ("/language", "\(settings.language.rawValue)"),
            ("/IsSteam", settings.platform == .steam ? "1" : "0"),
            ("/ver", FFXIVRepo.game.ver)
        ]
        return [
            app.dx11URL.path,
            StartGameOperation.encryptedArgs(args: args, ticks: ticks)
        ]
    }
}
