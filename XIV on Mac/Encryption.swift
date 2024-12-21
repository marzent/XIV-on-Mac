//
//  Encryption.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 18.03.22.
//

import CommonCrypto
import Foundation

struct Encryption {
    @available(*, unavailable) private init() {}

    static func blowfish(key: String, toEncrypt: [UInt8], broken: Bool = false)
        -> [UInt8]
    {
        var bytes = zeroPad(array: toEncrypt)
        let keyBytes = [UInt8](key.utf8)
        if broken {
            bytes = swapByteOrder32(bytes)
        }
        var cipher = [UInt8](repeating: 0, count: bytes.count)
        var bytesWritten = 0
        let op: CCOperation = UInt32(kCCEncrypt)
        let alg: CCAlgorithm = UInt32(kCCAlgorithmBlowfish)
        let opts: CCOptions = UInt32(kCCOptionECBMode)
        let status = CCCrypt(
            op, alg, opts, keyBytes, keyBytes.count, nil, bytes, bytes.count,
            &cipher, cipher.count, &bytesWritten)
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

    private static func swapByteOrder32(_ bytes: [UInt8]) -> [UInt8] {
        var mbytes = bytes
        for i in stride(from: 0, to: bytes.count, by: 4) {
            for j in 0..<4 {
                mbytes[i + j] = bytes[i + 3 - j]
            }
        }
        return mbytes
    }

    static func sha1(file: URL) throws -> (String, Int) {
        let data = try Data(contentsOf: file)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            CC_SHA1(bytes.baseAddress, UInt32(data.count), &hash)
        }
        return (Data(hash).hexStr, data.count)
    }
}

public class TOTP {
    internal init(secret: Data) {
        self.secret = secret
    }

    private let secret: Data
    private let period = TimeInterval(30)
    private let digits = 6

    public var token: String {
        var counter = UInt64(Date().timeIntervalSince1970 / period).bigEndian
        let counterData = withUnsafeBytes(of: &counter) { Array($0) }
        let key = Data(
            bytes: &counter, count: MemoryLayout.size(ofValue: counter))
        let (hashAlgorithm, hashLength) = (
            CCHmacAlgorithm(kCCHmacAlgSHA1), Int(CC_SHA1_DIGEST_LENGTH)
        )
        let hashPtr = UnsafeMutablePointer<Any>.allocate(
            capacity: Int(hashLength))
        defer {
            hashPtr.deallocate()
        }
        secret.withUnsafeBytes { secretBytes in
            // Generate the key from the counter value.
            counterData.withUnsafeBytes { counterBytes in
                CCHmac(
                    hashAlgorithm, secretBytes.baseAddress, secret.count,
                    counterBytes.baseAddress, key.count, hashPtr)
            }
        }
        let hash = Data(bytes: hashPtr, count: Int(hashLength))
        var truncatedHash = hash.withUnsafeBytes { ptr -> UInt32 in
            let offset = ptr[hash.count - 1] & 0x0F
            let truncatedHashPtr = ptr.baseAddress! + Int(offset)
            return truncatedHashPtr.bindMemory(to: UInt32.self, capacity: 1)
                .pointee
        }
        truncatedHash = UInt32(bigEndian: truncatedHash)
        truncatedHash = truncatedHash & 0x7FFF_FFFF
        truncatedHash = truncatedHash % UInt32(pow(10, Float(digits)))
        return String(format: "%0*u", digits, truncatedHash)
    }
}

extension Data {
    func toUInt32() -> UInt32 {
        let intBits = [UInt8](self).withUnsafeBufferPointer {
            ($0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) {
                $0
            })
        }.pointee
        return UInt32(littleEndian: intBits)
    }

    func squareBase64EncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "*")
    }

    var hexStr: String {
        return [UInt8](self).map { String(format: "%02hhx", $0) }.joined()
    }
}
