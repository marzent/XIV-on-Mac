//
//  Patch.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 25.02.22.
//

import Foundation

public class Patch {
    
    static let dir = Util.applicationSupport.appendingPathComponent("patch")
    static let cache = dir.appendingPathComponent("cache")
    
    init(_ input: [String]) {
        let hasHash = input.count == 9
        self.hashes = hasHash ? Hashes(type: input[5], blockSize: input[6], array: input[7]) : nil
        self.version = input[4]
        self.url = URL(string: hasHash ? input[8] : input[5])!
        self.length = Int64(input[0]) ?? 0
    }
    
    struct Hashes {
        internal init(type: String, blockSize: String, array: String) {
            self.type = type
            self.blockSize = UInt64(blockSize) ?? 0
            self.array = array.components(separatedBy: ",")
        }
        
        let type: String
        let blockSize: UInt64
        let array: [String]
    }
    
    let hashes: Hashes?
    let version: String
    let url: URL
    let length: Int64

    var name: String {
        [repo.rawValue, String(url.lastPathComponent.dropLast(6))].joined(separator: "/")
    }
    var path: String {
        url.pathComponents.dropFirst().joined(separator: "/")
    }
    var repo: FFXIVRepo {
        FFXIVRepo(rawValue: url.pathComponents[2]) ??
        (url.pathComponents[1] == "boot" ? .boot : .game)
    }
    
    static func parse(patches: String) -> [Patch] {
        patches.components(separatedBy: "\r\n")
            .dropFirst(5)
            .dropLast(2)
            .map {Patch($0.components(separatedBy: "\t"))}
    }
    
    static func totalLength(_ patches: [Patch]) -> Int64 {
        patches.map{$0.length}.reduce(0, +)
    }
    
    static func totalLength(_ patches: ArraySlice<Patch>) -> Int64 {
        totalLength(Array(patches))
    }
    
    static private let keepKey = "KeepPatches"
    static var keep: Bool {
        get {
            UserDefaults.standard.bool(forKey: keepKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keepKey)
        }
    }
}
