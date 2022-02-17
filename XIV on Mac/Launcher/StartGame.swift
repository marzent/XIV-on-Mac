//
//  StartGame.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Cocoa
import CryptoSwift

let checksumTable = [
    "f", "X", "1", "p", "G", "t", "d", "S",
    "5", "C", "A", "P", "4", "_", "V", "L"
]

var timebase: mach_timebase_info = mach_timebase_info()

func swapByteOrder32(_ bytes: [UInt8]) -> [UInt8]{
    var mbytes = bytes
    for i in stride(from: 0, to: bytes.count, by: 4) {
        for j in 0 ..< 4 {
            mbytes[i + j] = bytes[i + 3 - j]
        }
    }
    return mbytes
}

class StartGameOperation: AsyncOperation {
    let settings: FFXIVSettings
    let sid: String
    
    init(settings: FFXIVSettings, sid: String) {
        self.settings = settings
        self.sid = sid
        super.init()
    }
    
    override func main() {
        let app = FFXIVApp()
        let args = arguments(app: app)
        if settings.dalamud {
            Dalamud.launch(args: args, region: settings.region, gameVersion: app.gameVer)
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

    class func wineGetTickCount(timeFunc: () -> UInt64) -> UInt64 {
        if timebase.denom == 0 {
            mach_timebase_info(&timebase)
        }
        let machtime = timeFunc()
        let numer = UInt64(timebase.numer)
        let denom = UInt64(timebase.denom)
        let monotonic_time = machtime * numer / denom / 100
        return monotonic_time / 10000
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
        let index = Int((key & 0x000F0000) >> 16)
        return checksumTable[index]
    }

    class func zeroPadArray(array: [UInt8]) -> [UInt8] {
        let zeroes = Blowfish.blockSize - (array.count % Blowfish.blockSize)
        if zeroes > 0 {
            return array + [UInt8](repeating: 0, count: zeroes)
        }
        return array
    }

    class func encryptedArgs(args: [(String, String)], ticks: UInt64) -> String {
        let key = blowfishKey(ticks: ticks)
        let check = checksum(key: key)
        let keyStr = String(format: "%08x", key)
        let keyBytes = [UInt8](keyStr.utf8)
        let str = args.reduce(into: "") { (result, tuple) in
            let (key, value) = tuple
            result += " \(doubleSpaceify(key)) =\(doubleSpaceify(value))"
        }
        let bytes = swapByteOrder32(zeroPadArray(array: [UInt8](str.utf8)))
        let cipherText = try! Blowfish(key: keyBytes, blockMode: ECB(), padding: .zeroPadding).encrypt(bytes)

        // The cipherText is little endian and FFXIV wants big endian
        let b64 = Data(swapByteOrder32(cipherText)).base64EncodedString()
        let b64url = b64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")

        return "//**sqex0003\(b64url)\(check)**//"
    }
    
    func arguments(app: FFXIVApp) -> [String] {
        let ticks = StartGameOperation.wineGetTickCount(timeFunc: mach_absolute_time)
        let args = [
            ("/DEV.DataPathType", "1"),
            ("/DEV.MaxEntitledExpansionID", "\(settings.expansionId.rawValue)"),
            ("/DEV.TestSID", "\(sid)"),
            ("/DEV.UseSqPack", "1"),
            ("/SYS.Region", "\(settings.region.rawValue)"),
            ("/language", "\(settings.region.language.rawValue)"),
            ("/IsSteam", settings.steam ? "1" : "0"),
            ("/ver", "\(app.gameVer)")
        ]
        return [
            app.dx11URL.path,
            StartGameOperation.encryptedArgs(args: args, ticks: ticks)
        ]
    }
}
