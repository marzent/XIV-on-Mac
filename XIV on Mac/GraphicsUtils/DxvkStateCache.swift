//
//  DxvkStateCache.swift
//  DxvkStateCacheMerger
//
//  Created by Marc-Aurel Zent on 30.03.22.
//

import Foundation

struct DxvkStateCache {

    struct Header {
        static let byteSize = 12

        let magic: String
        let version: UInt32
        let entrySize: UInt32

        init(_ data: Data) throws {
            guard data.count == 12 else {
                throw DxvkError.invalidHeader
            }
            let chunks = [UInt8](data).chunked(into: 4)
            magic = String(chunks[0].map { Character(UnicodeScalar($0)) })
            guard magic == "DXVK" else {
                throw DxvkError.invalidHeader
            }
            version = Data(chunks[1]).toUInt32()
            entrySize = Data(chunks[2]).toUInt32()
        }

        var rawArray: [UInt8] {
            return magic.compactMap { $0.asciiValue }
                + withUnsafeBytes(of: version, Array.init)
                + withUnsafeBytes(of: entrySize, Array.init)
        }
    }

    struct Entry: Equatable, Hashable {
        static let headerByteSize = 24
        let stageMask: UInt8
        let sha1Hash: [UInt8]
        let data: Data

        init(_ entryData: Data) throws {
            let headerData = entryData.prefix(Entry.headerByteSize)
            guard headerData.count == Entry.headerByteSize else {
                throw DxvkError.invalidEntryHeader
            }
            stageMask = headerData.first!
            let dataSize24bit = [UInt8](headerData.dropFirst().prefix(3))
            let dataSize = Int(Data(dataSize24bit + [0]).toUInt32())
            sha1Hash = headerData.suffix(20)
            data = entryData.dropFirst(Entry.headerByteSize).prefix(dataSize)
            guard data.count == dataSize else {
                throw DxvkError.invalidEntryData
            }
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(data)
        }

        var rawArray: [UInt8] {
            return [stageMask]
                + withUnsafeBytes(of: UInt32(data.count), Array.init).prefix(3)
                + sha1Hash + data
        }

    }

    let header: Header
    var entries: [Entry] = []
    var rawData: Data {
        Data(entries.map { $0.rawArray }.reduce(header.rawArray, +))
    }

    internal init(header: Header, entries: [Entry] = []) {
        self.header = header
        self.entries = entries
    }

    init(inputData: Data) throws {
        header = try Header(inputData.prefix(Header.byteSize))
        var dataToProcess = inputData.dropFirst(Header.byteSize)
        while dataToProcess.count > 0 {
            entries.append(try Entry(dataToProcess))
            dataToProcess = dataToProcess.dropFirst(
                entries.last!.data.count + Entry.headerByteSize)
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
