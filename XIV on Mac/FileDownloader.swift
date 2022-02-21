//
//  FileDownloader.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 22.12.21.
//

import Foundation

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

    
    static func loadFileAsync(url: URL, semaphore: DispatchSemaphore) -> URLSessionDownloadTask? {
        let downloadUrl = Util.cache
        let destinationUrl = downloadUrl.appendingPathComponent(url.lastPathComponent)

        if FileManager().fileExists(atPath: destinationUrl.path)
        {
            print("File already exists [\(destinationUrl.path)]")
            semaphore.signal()
            return nil
        }
        let downloadTask = URLSession.shared.downloadTask(with: url) {
            urlOrNil, responseOrNil, errorOrNil in
            guard let fileURL = urlOrNil else { return }
            do {
                try FileManager.default.moveItem(at: fileURL, to: destinationUrl)
            } catch {
                print ("file error: \(error)")
            }
            semaphore.signal()
        }
        return downloadTask
    }

}
