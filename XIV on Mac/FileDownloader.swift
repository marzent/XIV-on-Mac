//
//  FileDownloader.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 22.12.21.
//

import Foundation

class FileDownloader {

    static func loadFileSync(url: URL, completion: @escaping (String?, Error?) -> Void) {
        let downloadUrl = Util.cache
        let destinationUrl = downloadUrl.appendingPathComponent(url.lastPathComponent)

        if FileManager().fileExists(atPath: destinationUrl.path) {
            print("File already exists [\(destinationUrl.path)]")
            completion(destinationUrl.path, nil)
        }
        else if let dataFromURL = NSData(contentsOf: url) {
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

    
    static func loadFileAsync(url: String, onFinish: @escaping (_: String) -> Void)
    {
        let downloadUrl = Util.cache
        let _url = URL(string: url)!
        let destinationUrl = downloadUrl.appendingPathComponent(_url.lastPathComponent)

        if FileManager().fileExists(atPath: destinationUrl.path)
        {
            print("File already exists [\(destinationUrl.path)]")
            onFinish(url)
        }
        else {
            let downloadTask = URLSession.shared.downloadTask(with: _url) {
                urlOrNil, responseOrNil, errorOrNil in
                guard let fileURL = urlOrNil else { return }
                do {
                    try FileManager.default.moveItem(at: fileURL, to: destinationUrl)
                    onFinish(url)
                } catch {
                    print ("file error: \(error)")
                }
            }
            downloadTask.resume()
        }
    }

}
