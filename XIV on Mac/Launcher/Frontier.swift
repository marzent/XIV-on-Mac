//
//  Frontier.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 07.02.22.
//

import Foundation

class Frontier {
    
    struct Info: Codable {
        
        struct News: Codable {
            let date: String
            let title: String
            let url: String
            let id: String
            let tag: String?
        }
        
        struct Banner: Codable {
            let lsbBanner: String
            let link: String

            enum CodingKeys: String, CodingKey {
                case lsbBanner = "lsb_banner"
                case link
            }
        }
        
        let news, topics, pinned: [News]
        let banner: [Banner]
    }
    
    static var info: Info? {
        var ret: Info?
        let time = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
        let lang = FFXIVRegion.guessFromLocale().language.code
        let url = URL(string: "https://frontier.ffxiv.com/news/headline.json?lang=\(lang)&media=pcapp&\(time)")!
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                let fixedData = String(decoding: data, as: UTF8.self).unescapingUnicodeCharacters.data(using: .utf8)! //thx square
                let jsonDecoder = JSONDecoder()
                do {
                    ret = try jsonDecoder.decode(Info.self, from: fixedData)
                } catch {
                    print(error, to: &Util.logger)
                }
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        return ret
    }

}

extension String {
    var unescapingUnicodeCharacters: String {
        let mutableString = NSMutableString(string: self)
        CFStringTransform(mutableString, nil, "Any-Hex/Java" as NSString, true)

        return mutableString as String
    }
}
