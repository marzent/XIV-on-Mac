//
//  Networking.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 22.12.21.
//

import Foundation
import OrderedCollections
import CcURLSwift
import SeeURL

extension HTTPClient {
    
    static func fetch(url: URL, headers: OrderedDictionary<String, String>? = nil, postBody: Data = Data(), proxy: String? = nil) -> Response? {
        let headers = headers?.map {key, value in (key,value)} ?? []
        let body = [UInt8](postBody)
        let method = body.isEmpty ? "GET" : "POST"
        return try? sendRequest(method: method, url: url.absoluteString, headers: headers, body: body)
    }
    
    private class Progress {
        internal init() {
            self.total = 0
            self.now = 0
        }
        var total: Double
        var now: Double
    }
    
    static func fetchFile(url: URL, destinationUrl: URL? = nil, headers: OrderedDictionary<String, String>? = nil, proxy: String? = nil, maxSpeed: Int = 0, progressCallback: ((Int64, Int64, Int64) -> Void)? = nil) throws {
        let destURL = destinationUrl ?? Util.cache.appendingPathComponent(url.lastPathComponent)
        if FileManager().fileExists(atPath: destURL.path) {
            print("File already exists [\(destURL.path)]")
            return
        }
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + "/" + UUID().uuidString)
        guard let fileHandle = tempURL.withUnsafeFileSystemRepresentation( { fopen($0, "wb") }) else {
            throw cURL.Error.FailedInitialization
        }
        defer {
            fclose(fileHandle)
        }
        Util.make(dir: tempURL.deletingLastPathComponent())
        Util.make(dir: destURL.deletingLastPathComponent())
        
        let curl = cURL()
        try curl.set(option: CURLOPT_URL, url.absoluteString)
        try curl.set(option: CURLOPT_FOLLOWLOCATION, true)
        try curl.set(option: CURLOPT_LOW_SPEED_TIME, 120)
        try curl.set(option: CURLOPT_LOW_SPEED_LIMIT, 30)
        try curl.set(option: CURLOPT_MAX_RECV_SPEED_LARGE, maxSpeed)
        if let proxy = proxy {
            try curl.set(option: CURLOPT_PROXY, proxy)
        }
        if let curlHeaders = headers?.map({key, value in "\(key): \(value)"}) {
            try curl.set(option:CURLOPT_HTTPHEADER, curlHeaders)
        }
        else {
            try curl.set(option: CURLOPT_USERAGENT, "curl/7.77.0")
        }
        
        func writeFile(contents: UnsafeMutablePointer<Int8>?, size: Int, nmemb: Int, file: UnsafeMutableRawPointer?) -> Int {
            guard let contents = contents, let file = file else {
                return 0
            }
            let filePtr = UnsafeMutablePointer<FILE>(OpaquePointer(file))
            return fwrite(contents, size, nmemb, filePtr)
        }
        try curl.set(option:CURLOPT_WRITEFUNCTION, writeFile)
        try curl.set(option:CURLOPT_WRITEDATA, fileHandle)
        
        func updateProgress(ptr: UnsafeMutableRawPointer?, dltotal: Double, dlnow: Double, ultotal: Double, ulnow: Double) -> Int32 {
            guard let progPtr = ptr else {
                return 0
            }
            let progress = Unmanaged<Progress>.fromOpaque(progPtr).takeUnretainedValue()
            progress.total = dltotal
            progress.now = dlnow
            return 0
        }
        let progress = Progress()
        var lastDownloadedBytes: Double = 0
        var timer: Timer?
        defer {
            timer?.invalidate()
        }
        if let callback = progressCallback {
            try curl.set(option:CURLOPT_NOPROGRESS, false)
            try curl.set(option:CURLOPT_PROGRESSFUNCTION, updateProgress)
            try curl.set(option:CURLOPT_XFERINFODATA, Unmanaged.passUnretained(progress))
            DispatchQueue.main.async {
                let updateInterval = 0.5
                timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
                    guard progress.now > 0 else {
                        return
                    }
                    let speed = (progress.now - lastDownloadedBytes) / updateInterval
                    lastDownloadedBytes = progress.now
                    callback(Int64(progress.total), Int64(progress.now), Int64(speed))
                    
                }
            }
        }
        
        try curl.perform()
        let response = try curl.get(info: CURLINFO_RESPONSE_CODE) as Int
        if response == 200 {
            try FileManager.default.moveItem(at: tempURL, to: destURL)
        }
        else {
            throw cURL.Error.CouldNotConnect
        }
    }
    
}
