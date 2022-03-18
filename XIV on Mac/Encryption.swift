//
//  Encryption.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 18.03.22.
//

import Foundation
import CommonCrypto

struct Encryption {
    @available(*, unavailable) private init() {}
    
    static func blowfish(key: String, toEncrypt: [UInt8], broken: Bool = false) -> [UInt8] {
        var bytes = zeroPad(array: toEncrypt)
        let keyBytes = [UInt8](key.utf8)
        if broken {
            bytes = swapByteOrder32(bytes)
        }
        var cipher = [UInt8](repeating: 0, count: bytes.count)
        var bytesWritten: Int = 0
        let op: CCOperation = UInt32(kCCEncrypt)
        let alg: CCAlgorithm = UInt32(kCCAlgorithmBlowfish)
        let opts: CCOptions = UInt32(kCCOptionECBMode)
        let status = CCCrypt(op, alg, opts, keyBytes, keyBytes.count, nil, bytes, bytes.count, &cipher, cipher.count, &bytesWritten)
        assert(UInt32(status) == UInt32(kCCSuccess))
        if broken {
            return swapByteOrder32(cipher)
        }
        return cipher
    }

    private static func zeroPad(array: [UInt8]) -> [UInt8] {
        let zeroes = kCCBlockSizeBlowfish - (array.count % kCCBlockSizeBlowfish)
        if zeroes > 0 {
            return array + [UInt8](repeating: 0, count: zeroes)
        }
        return array
    }
    
    private static func swapByteOrder32(_ bytes: [UInt8]) -> [UInt8]{
        var mbytes = bytes
        for i in stride(from: 0, to: bytes.count, by: 4) {
            for j in 0 ..< 4 {
                mbytes[i + j] = bytes[i + 3 - j]
            }
        }
        return mbytes
    }
    
    static func sha1(file: URL) throws -> (String, Int) {
        let data = try Data.init(contentsOf: file)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Void in
            CC_SHA1(bytes.baseAddress, UInt32(data.count), &hash)
        }
        return (Data(hash).hexStr, data.count)
    }
}

extension Data {
    func toUInt32() -> UInt32 {
        let intBits = self.bytes.withUnsafeBufferPointer {
            ($0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 })
        }.pointee
      return UInt32(littleEndian: intBits)
    }
    
    func squareBase64EncodedString() -> String {
        self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "*")
    }
    
    var hexStr: String {
        return self.bytes.map { String(format: "%02hhx", $0) }.joined()
    }
}
