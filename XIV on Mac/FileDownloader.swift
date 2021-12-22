//
//  FileDownloader.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 22.12.21.
//

import Foundation

class FileDownloader {

    static func loadFileAsync(url: URL)
    {
        let downloadUrl = Util.cache
        let destinationUrl = downloadUrl.appendingPathComponent(url.lastPathComponent)

        if FileManager().fileExists(atPath: destinationUrl.path)
        {
            print("File already exists [\(destinationUrl.path)]")
        }
        else {
            let downloadTask = URLSession.shared.downloadTask(with: url) {
                urlOrNil, responseOrNil, errorOrNil in
                // check for and handle errors:
                // * errorOrNil should be nil
                // * responseOrNil should be an HTTPURLResponse with statusCode in 200..<299
                
                guard let fileURL = urlOrNil else { return }
                do {
                    try FileManager.default.moveItem(at: fileURL, to: destinationUrl)
                } catch {
                    print ("file error: \(error)")
                }
            }
            downloadTask.resume()
        }
    }

}
