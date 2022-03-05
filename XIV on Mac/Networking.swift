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

fileprivate let progressNotification = NotificationCenter()

private class ProgressObserver {
    var callback: ((Double, Double) -> Void)?
    
    internal init(_ progPtr: UnsafeMutableRawPointer) {
        progressNotification.addObserver(self, selector: #selector(self.observe(_:)), name: Notification.Name(rawValue: "\(progPtr)"), object: nil)
    }
    
    @objc func observe(_ notif: Notification) {
        guard let callback = callback else {
            return
        }
        let dict = notif.userInfo! as Dictionary
        let total = dict["total"] as! Double
        let now = dict["now"] as! Double
        callback(total, now)
    }
}

extension HTTPClient {
    
    static func fetch(url: URL, headers: OrderedDictionary<String, String>? = nil, postBody: Data = Data(), proxy: String? = nil) -> Response? {
        let headers = headers?.map {key, value in (key,value)} ?? []
        let body = [UInt8](postBody)
        let method = body.isEmpty ? "GET" : "POST"
        return try? sendRequest(method: method, url: url.absoluteString, headers: headers, body: body)
    }
    
    static func fetchFile(url: URL, destinationUrl: URL? = nil, headers: OrderedDictionary<String, String>? = nil, proxy: String? = nil, progressCallback: ((Double, Double) -> Void)? = nil) throws {
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
            guard let progPtr = ptr, dltotal > 0, Int(dlnow) % 7 == 0 else {
                return 0
            }
            progressNotification.post(name: Notification.Name("\(progPtr)"), object: nil, userInfo: ["total": dltotal, "now": dlnow])
            return 0
        }
        let progData = cURL.WriteFunctionStorage()
        let progressObserver = ProgressObserver(Unmanaged.passUnretained(progData).toOpaque())
        if let progressCallback = progressCallback {
            try curl.set(option:CURLOPT_NOPROGRESS, false)
            try curl.set(option:CURLOPT_PROGRESSFUNCTION, updateProgress)
            try curl.set(option:CURLOPT_XFERINFODATA, Unmanaged.passUnretained(progData))
            progressObserver.callback = progressCallback
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
