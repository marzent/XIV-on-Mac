//
//  Steamworks.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 09.03.22.
//

import Foundation
import CryptoSwift

struct Steam {
    @available(*, unavailable) private init() {}
    
    private static var steamworks: Steamworks?
    
    static func initAPI() {
        let appId = FFXIVSettings.freeTrial ? 312060 : 39210
        if let steamworks = steamworks {
            steamworks.reinit(withAppId: appId)
        }
        else {
            steamworks = Steamworks(appId: appId)
        }
    }
    
    private class CrtRand {
        internal init(seed: UInt32) {
            self.seed = seed
        }
        
        private var seed: UInt32
        
        var number: UInt32 {
            seed = 0x343FD &* seed &+ 0x269EC3;
            return ((seed >> 16) & 0xFFFF) & 0x7FFF
        }
    }
    
    typealias Ticket = (text: String, length: Int)
    
    
    static var ticket: Ticket? {
        //snoat was here
        //all credits go to the XL team for reverse engineering this, I do not even own a steam license :)
        guard let rawTicketSteam = steamworks?.authSessionTicket else {
            return nil
        }
        let ticketString = rawTicketSteam.map { String(format: "%02hhx", $0) }.joined()
        let rawTicket = ticketString.compactMap { $0.asciiValue } + [0]
        let ticketSum = rawTicket.map { UInt16($0) }.reduce(0, &+)
        let ticketSumTruncated = Int32(Int16(truncatingIfNeeded: ticketSum))
        let time = 60 * ((steamworks!.serverRealTime - 5) / 60);
        let rand = CrtRand(seed: time ^ UInt32(bitPattern: ticketSumTruncated))
        let blowfishKey = String(format: "%08x#un@e=x>", time)
        let numRandomBytes = (UInt64(rawTicket.count + 9) & 0xFFFFFFFFFFFFFFF8) - 2 - UInt64(rawTicket.count)
        let fuckedBytes = withUnsafeBytes(of: ticketSum, Array.init) + rawTicket
        let fuckedGarbageAlphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_")
            .compactMap { $0.asciiValue }
        var fuckedSum = Data(bytes: fuckedBytes, count: 4).toUInt32()
        var garbage = [UInt8](repeating: 0, count: Int(numRandomBytes))
        for i in 0..<numRandomBytes {
            let randChar = fuckedGarbageAlphabet[Int(Int32(fuckedSum &+ rand.number) & 0x3F)]
            garbage[Int(i)] = randChar
            fuckedSum &+= UInt32(randChar)
        }
        var finalBytes = withUnsafeBytes(of: fuckedSum, Array.init) + Array(rawTicket.dropFirst(2)) + garbage
        finalBytes.swapAt(0, 1)
        let keyBytes = [UInt8](blowfishKey.utf8)
        let cipherText = try! Blowfish(key: keyBytes, blockMode: ECB(), padding: .zeroPadding).encrypt(finalBytes)
        let encodedCipher = Data(cipherText).squareBase64EncodedString()
        let components = encodedCipher.components(withMaxLength: 300)
        let finalString = components.joined(separator: ",")
        return (text: finalString, length: finalString.count - (components.count - 1))
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
}

extension String {
    func components(withMaxLength length: Int) -> [String] {
        return stride(from: 0, to: self.count, by: length).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            return String(self[start..<end])
        }
    }
}
