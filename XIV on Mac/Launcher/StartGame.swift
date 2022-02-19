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
        let app = FFXIVApp()
        let args = arguments(app: app)
        if settings.dalamud {
            Dalamud.launch(args: args, language: settings.language, gameVersion: app.gameVer)
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
        let cipherText = try! Blowfish(key: keyBytes, blockMode: ECB(), padding: .zeroPadding).brokenSquareEncrypt(argStr)
        return "//**sqex0003\(cipherText)\(check)**//"
    }
    
    func arguments(app: FFXIVApp) -> [String] {
        let ticks = Wine.tickCount
        let args = [
            ("/DEV.DataPathType", "1"),
            ("/DEV.MaxEntitledExpansionID", "\(settings.expansionId.rawValue)"),
            ("/DEV.TestSID", "\(sid)"),
            ("/DEV.UseSqPack", "1"),
            ("/SYS.Region", "\(settings.region.rawValue)"),
            ("/language", "\(settings.language.rawValue)"),
            ("/IsSteam", settings.platform == .steam ? "1" : "0"),
            ("/ver", "\(app.gameVer)")
        ]
        return [
            app.dx11URL.path,
            StartGameOperation.encryptedArgs(args: args, ticks: ticks)
        ]
    }
}

extension Blowfish {
    private func zeroPadArray(array: [UInt8]) -> [UInt8] {
        let zeroes = Blowfish.blockSize - (array.count % Blowfish.blockSize)
        if zeroes > 0 {
            return array + [UInt8](repeating: 0, count: zeroes)
        }
        return array
    }
    
    func brokenSquareEncrypt(_ data: String) throws -> String {
        let bigEndianBytes = Util.swapByteOrder32(zeroPadArray(array: [UInt8](data.utf8)))
        let cipherText = try self.encrypt(bigEndianBytes)
        let bigEndianCipher = Data(Util.swapByteOrder32(cipherText)).base64EncodedString()
        return bigEndianCipher.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_") //thx square
    }
}
