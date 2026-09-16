//
//  Dxmt.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 16.09.26.
//

import Foundation

enum Dxmt {
    static func resetCache() throws {
        let cacheURL = try shaderCacheURL()
        let fm = FileManager.default
        guard fm.fileExists(atPath: cacheURL.path) else {
            return
        }
        try fm.removeItem(at: cacheURL)
    }

    private static func shaderCacheURL() throws -> URL {
        try darwinUserCacheDirectory()
            .appendingPathComponent("dxmt", isDirectory: true)
            .appendingPathComponent("ffxiv_dx11.exe", isDirectory: true)
    }

    private static func darwinUserCacheDirectory() throws -> URL {
        var buffer = [CChar](repeating: 0, count: Int(PATH_MAX))
        let length = confstr(_CS_DARWIN_USER_CACHE_DIR, &buffer, buffer.count)
        guard length > 0 else {
            throw POSIXError(.ENOENT)
        }
        return URL(fileURLWithPath: String(cString: buffer), isDirectory: true)
    }
}
