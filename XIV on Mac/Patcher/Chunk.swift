//
//  Chunk.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 18.02.22.
//

import Foundation

extension ZiPatch {
    class Chunk {
        
        class Header: NSData {
            var size: UInt32 {
                return bytes.load(as: UInt32.self)
            }
            var name: String? {
                let nameBuffer = UnsafeBufferPointer(start: (bytes + 4).bindMemory(to: UInt8.self, capacity: 4), count: 4)
                return String(bytes: Array(nameBuffer), encoding: .ascii)
            }
        }
        
        var header = Header()
        var crc32: UInt32 = 0
    }
}
