//
//  StartGame.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Cocoa
import CommonCrypto

let checksumTable = [
    "f", "X", "1", "p", "G", "t", "d", "S",
    "5", "C", "A", "P", "4", "_", "V", "L"
]

var timebase: mach_timebase_info = mach_timebase_info()

func swapByteOrder32(bytes: inout [UInt8]) {
    for i in stride(from: 0, to: bytes.count, by: 4) {
        let b0 = bytes[i.advanced(by: 0)]
        let b1 = bytes[i.advanced(by: 1)]
        let b2 = bytes[i.advanced(by: 2)]
        let b3 = bytes[i.advanced(by: 3)]
        bytes[i.advanced(by: 0)] = b3
        bytes[i.advanced(by: 1)] = b2
        bytes[i.advanced(by: 2)] = b1
        bytes[i.advanced(by: 3)] = b0
    }
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
        let zeroes = kCCBlockSizeBlowfish - (array.count % kCCBlockSizeBlowfish)
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
        var bytes = zeroPadArray(array: [UInt8](str.utf8))
        // Fix these bytes being big endian, when CCCrypt wants little endian
        swapByteOrder32(bytes: &bytes)

        var cipherText = [UInt8](repeating: 0, count: bytes.count)
        var bytesWritten: Int = 0

        let op: CCOperation = UInt32(kCCEncrypt)
        let alg: CCAlgorithm = UInt32(kCCAlgorithmBlowfish)
        let opts: CCOptions = UInt32(kCCOptionECBMode)
        let status = CCCrypt(op,
                             alg,
                             opts,
                             keyBytes,
                             keyBytes.count,
                             nil,
                             bytes,
                             bytes.count,
                             &cipherText,
                             cipherText.count,
                             &bytesWritten)
        assert(UInt32(status) == UInt32(kCCSuccess))

        // The cipherText is little endian and FFXIV wants big endian
        swapByteOrder32(bytes: &cipherText)

        let b64 = Data(cipherText).base64EncodedString()
        let b64url = b64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")

        return "//**sqex0003\(b64url)\(check)**//"
    }
    
    func arguments(app: FFXIVApp) -> [String] {
        let ticks = StartGameOperation.wineGetTickCount(timeFunc: mach_absolute_time)
        let args = [
            ("T", "\(ticks & 0xFFFFFFFF)"),
            ("/DEV.DataPathType", "1"),
            ("/DEV.MaxEntitledExpansionID", "\(settings.expansionId.rawValue)"),
            ("/DEV.TestSID", "\(sid)"),
            ("/DEV.UseSqPack", "1"),
            ("/SYS.Region", "\(settings.region.rawValue)"),
            ("/language", "1"),
            ("/IsSteam", settings.steam ? "1" : "0"),
            ("/ver", "\(app.gameVer)")
        ]
        return [
            Wine.prefix.appendingPathComponent("drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn/game/ffxiv_dx11.exe").path,
            StartGameOperation.encryptedArgs(args: args, ticks: ticks)
        ]
    }
}
