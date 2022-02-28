//
//  FileDownloader.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 22.12.21.
//

import Foundation
import OrderedCollections

class FileDownloader {

    static func loadFileSync(url: URL, destination: URL = Util.cache, completion: @escaping (String?, Error?) -> Void) {
        let destinationUrl = destination.appendingPathComponent(url.lastPathComponent)
        
        if FileManager().fileExists(atPath: destinationUrl.path) {
            print("File already exists [\(destinationUrl.path)]")
            completion(destinationUrl.path, nil)
        }
        else if let dataFromURL = NSData(contentsOf: url) {
            Util.make(dir: destination.path)
            if dataFromURL.write(to: destinationUrl, atomically: true) {
                print("file saved [\(destinationUrl.path)]")
                completion(destinationUrl.path, nil)
            } else {
                print("error saving file")
                let error = NSError(domain:"Error saving file", code:1001, userInfo:nil)
                completion(destinationUrl.path, error)
            }
        }
        else {
            let error = NSError(domain:"Error downloading file", code:1002, userInfo:nil)
            completion(destinationUrl.path, error)
        }
    }

    
    static func loadFileAsync(url: URL, headers: OrderedDictionary<String, String>? = nil, destinationUrl: URL? = nil, completion: @escaping (URLResponse?) -> Void) -> URLSessionDownloadTask? {
        let destURL = destinationUrl == nil ? Util.cache.appendingPathComponent(url.lastPathComponent) : destinationUrl!
        if FileManager().fileExists(atPath: destURL.path)
        {
            print("File already exists [\(destURL.path)]")
            completion(nil)
            return nil
        }
        Util.make(dir: destURL.deletingLastPathComponent())
        var req = URLRequest(url: url)
        if let headers = headers {
            for (hdr, val) in headers {
                req.addValue(val, forHTTPHeaderField: hdr)
            }
        }
        //req.timeoutInterval = 60
        let downloadTask = URLSession.shared.downloadTask(with: req) { urlOrNil, responseOrNil, errorOrNil in
            guard let fileURL = urlOrNil else {
                return completion(responseOrNil)
            }
            do {
                try FileManager.default.moveItem(at: fileURL, to: destURL)
            } catch {
                print ("file error: \(error)")
            }
            completion(responseOrNil)
        }
        return downloadTask
    }

}
