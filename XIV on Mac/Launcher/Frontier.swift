//
//  Frontier.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 07.02.22.
//

import Foundation
import OrderedCollections
import SeeURL

class Frontier {
    
    static var squareTime: Int64 {
        Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
    }
    
    static var referer: URL {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd-HH"
        let time = dateFormatter.string(from: Date())
        let lang = FFXIVSettings.language.code
        return URL(string: "https://launcher.finalfantasyxiv.com/v600/index.html?rc_lang=\(lang)&time=\(time)")!
    }
    
    static var headline: URL {
        let lang = FFXIVSettings.language.code
        return URL(string: "https://frontier.ffxiv.com/news/headline.json?lang=\(lang)&media=pcapp&\(squareTime)")!
    }
    
    static func fetch(url: URL, accept: String? = nil, proxy: String? = nil) -> HTTPClient.Response? {
        let headers: OrderedDictionary = [
            "User-Agent"     : FFXIVLogin.userAgent,
            "Accept"         : accept,
            "Accept-Encoding": "gzip, deflate",
            //"Accept-Language": ??? TODO: find out how this works and why
            "Origin"         : "https://launcher.finalfantasyxiv.com",
            "Referer"        : Frontier.referer.absoluteString
        ]
        return HTTPClient.fetch(url: url, headers: headers, proxy: proxy)
    }
    
    struct Gate: Codable {
        let status: Int
    }
    
    static func checkGate() -> Bool {
        let url = URL(string: "https://frontier.ffxiv.com/worldStatus/gate_status.json?\(squareTime)")!
        guard let response = fetch(url: url) else {
            return false
        }
        guard let data = String(decoding: response.body, as: UTF8.self).unescapingUnicodeCharacters.data(using: .utf8) else {
            return false
        }
        let jsonDecoder = JSONDecoder()
        do {
            return try jsonDecoder.decode(Gate.self, from: data).status == 1
        } catch {
            return false
        }
    }
    
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
        guard let response = fetch(url: headline) else {
            return nil
        }
        guard let data = String(decoding: response.body, as: UTF8.self).unescapingUnicodeCharacters.data(using: .utf8) else {
            return nil
        }
        let jsonDecoder = JSONDecoder()
        do {
            return try jsonDecoder.decode(Info.self, from: data)
        } catch {
            return nil
        }
    }

}

extension String {
    var unescapingUnicodeCharacters: String {
        let mutableString = NSMutableString(string: self)
        CFStringTransform(mutableString, nil, "Any-Hex/Java" as NSString, true)

        return mutableString as String
    }
}
