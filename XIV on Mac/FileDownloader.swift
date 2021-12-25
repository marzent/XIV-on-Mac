//
//  FileDownloader.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 22.12.21.
//

import Foundation

class FileDownloader {

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
                // check for and handle errors:
                // * errorOrNil should be nil
                // * responseOrNil should be an HTTPURLResponse with statusCode in 200..<299
                
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
