//
//  FFXIVLoginServices.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Foundation
import KeychainAccess
import OrderedCollections
import SeeURL

struct FFXIVLogin {
    typealias settings = FFXIVSettings
    let ticket = Steam.ticket
    let authURL = URL(string: "https://ffxiv-login.square-enix.com/oauth/ffxivarr/login/login.send")!
    
    static var userAgent: String {
        settings.platform == .mac ? "macSQEXAuthor/2.0.0(MacOSX; ja-jp)" : "SQEXAuthor/2.0.0(Windows 6.2; ja-jp; \(uniqueID))"
    }
    
    static var userAgentPatch: String {
        settings.platform == .mac ? "FFXIV-MAC PATCH CLIENT" : "FFXIV PATCH CLIENT"
    }
    
    var authTopURL: URL {
        get throws {
            let isSteam = settings.platform == .steam
            let base = "https://ffxiv-login.square-enix.com/oauth/ffxivarr/login/top?lng=en&rgn=\(settings.region.rawValue)&isft=\(settings.freeTrial ? 1 : 0)&cssmode=1&isnew=1&launchver=3&issteam=\(isSteam ? 1 : 0)"
            guard isSteam else {
                return URL(string: base)!
            }
            guard let ticket = ticket else {
                throw FFXIVLoginError.noSteamTicket
            }
            let steamParams = "&session_ticket=\(ticket.text)&ticket_size=\(ticket.length)"
            return URL(string: base + steamParams)!
        }
    }
    
    static var patchURL: URL {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm"
        let time = dateFormatter.string(from: Date()).dropLast() + "0"
        return URL(string: "http://patch-bootver.ffxiv.com/http/win32/ffxivneo_release_boot/\(FFXIVRepo.boot.ver)/?time=\(time)")! //yes http this is not a mistake
    }
    
    var sessionURL: URL {
        return URL(string: "https://patch-gamever.ffxiv.com/http/win32/ffxivneo_release_game/\(FFXIVRepo.game.ver)")!
    }
    
    private var authTop: (stored: String, cookie: String?, squexid: String?) {
        get throws {
            let headers: OrderedDictionary = [
                "Accept"         : "*/*",
                "Host"           : "ffxiv-login.square-enix.com",
                "User-Agent"     : FFXIVLogin.userAgent,
                "Referer"        : "about:blank",
                "Accept-Encoding": "gzip, deflate",
                "Connection"     : "Keep-Alive",
                "Cookie"         : #"_rsid="""#
            ]
            guard let response = HTTPClient.fetch(url: try authTopURL, headers: headers) else {
                throw FFXIVLoginError.networkError
            }
            guard let html = String(data: response.body, encoding: .utf8) else {
                throw FFXIVLoginError.networkError
            }
            let recvHeaders = OrderedDictionary(response.headers, uniquingKeysWith: {$1})
            let cookie = recvHeaders["Set-Cookie"]
            guard let storedRange = html.range(of: #"(?<=name="_STORED_" value=").*(?=">)"#, options: .regularExpression) else {
                throw FFXIVLoginError.protocolError
            }
            let stored = String(html[storedRange])
            guard settings.platform == .steam else {
                return (stored: stored, cookie: cookie, squexid: nil)
            }
            guard let steamRange = html.range(of: #"(?<=<input name="sqexid" type="hidden" value=").*(?=")"#, options: .regularExpression) else {
                throw FFXIVLoginError.noSteamTicket
            }
            let squexid = String(html[steamRange])
            return (stored: stored, cookie: cookie, squexid: squexid)
        }
    }
    
    private var sessionId: String {
        get throws {
            let (stored, cookie, squexid) = try authTop
            let headers: OrderedDictionary = [
                "Accept"         : "*/*",
                "Host"           : "ffxiv-login.square-enix.com",
                "User-Agent"     : FFXIVLogin.userAgent,
                "Referer"        : try authTopURL.absoluteString,
                "Content-Type"   : "application/x-www-form-urlencoded",
                "Accept-Encoding": "gzip, deflate",
                "Connection"     : "Keep-Alive",
                "Cache-Control"  : "no-cache",
                "Cookie"         : cookie ?? #"_rsid="""#
            ]
            if let squexid = squexid {
                guard settings.credentials!.username.caseInsensitiveCompare(squexid) == .orderedSame else {
                    throw FFXIVLoginError.steamUserError
                }
            }
            else {
                guard settings.platform != .steam else {
                    throw FFXIVLoginError.steamUserError
                }
            }
            let postBody = settings.credentials!.loginData(storedSID: stored)
            guard let response = HTTPClient.fetch(url: authURL, headers: headers, postBody: postBody) else {
                throw FFXIVLoginError.networkError
            }
            guard let html = String(data: response.body, encoding: .utf8) else {
                throw FFXIVLoginError.networkError
            }
            guard let parsedResult = FFXIVServerLoginResponse(html: html) else {
                throw FFXIVLoginError.protocolError
            }
            guard parsedResult.authOk else {
                throw FFXIVLoginError.incorrectCredentials
            }
            guard let playable = parsedResult.playable else {
                throw FFXIVLoginError.protocolError
            }
            guard playable == 1 else {
                throw FFXIVLoginError.notPlayable
            }
            guard let sid = parsedResult.sid else {
                throw FFXIVLoginError.protocolError
            }
            settings.update(from: parsedResult)
            return sid
        }
    }
    
    var result: (uid: String, patches: [Patch]) {
        get throws {
            guard FFXIVApp().installed else {
                throw FFXIVLoginError.noInstall
            }
            if FFXIVApp.instances >= 2 {
                throw FFXIVLoginError.multibox
            }
            if Frontier.loginMaintenance {
                throw FFXIVLoginError.maintenance
            }
            let headers: OrderedDictionary = [
                "X-Hash-Check": "enabled",
                "User-Agent": FFXIVLogin.userAgentPatch
            ]
            let sid =  try sessionId
            let url = sessionURL.appendingPathComponent(sid)
            let postBody = FFXIVApp().versionList(maxEx: settings.expansionId.rawValue).data(using: .utf8)!
            guard let response = HTTPClient.fetch(url: url, headers: headers, postBody: postBody) else {
                throw FFXIVLoginError.networkError
            }
            if response.statusCode == 409 { //this means a boot update is required although we checked for it before... install is probably broken af
                throw FFXIVLoginError.protocolError
            }
            guard let html = String(data: response.body, encoding: .utf8) else {
                throw FFXIVLoginError.networkError
            }
            let recvHeaders = OrderedDictionary(response.headers, uniquingKeysWith: {$1})
            guard let uid = recvHeaders["X-Patch-Unique-Id"] else {
                throw FFXIVLoginError.protocolError
            }
            guard html.count == 0 else { //patching needed
                return (uid: uid, patches: Patch.parse(patches: html))
            }
            if Frontier.gameMaintenance {
                throw FFXIVLoginError.maintenance
            }
            if FFXIVRepo.boot.ver == "2022.03.25.0000.0001" {
                if settings.platform != .steam {
                    FFXIVApp().startOfficialLauncher()
                }
                throw FFXIVLoginError.killswitch
            }
            return (uid: uid, patches: [])
        }
    }
    
    static var bootPatches: [Patch] {
        get throws {
            let headers: OrderedDictionary = [
                "User-Agent": FFXIVLogin.userAgentPatch,
                "Host"      : "patch-bootver.ffxiv.com"
            ]
            guard FFXIVApp().installed else {
                throw FFXIVLoginError.noInstall
            }
            guard let response = HTTPClient.fetch(url: patchURL, headers: headers) else {
                throw FFXIVLoginError.networkError
            }
            guard let html = String(data: response.body, encoding: .utf8) else {
                throw FFXIVLoginError.networkError
            }
            return Patch.parse(patches: html)
        }
    }
    
    private static var uniqueID: String {
        let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice") )
        let fallbackID = "ecf4a84335"
        
        guard platformExpert > 0 else {
            return fallbackID
        }
        guard let serialNumber = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String) else {
            return fallbackID
        }
        IOObjectRelease(platformExpert)
        
        return String(serialNumber.lowercased().prefix(10))
    }
}

extension FFXIVSettings {
    
    static func update(from response: FFXIVServerLoginResponse) {
        if let rgnInt = response.region, let rgn = FFXIVRegion(rawValue: rgnInt) {
            region = rgn
        }
        if let expInt = response.maxEx, let expId = FFXIVExpansionLevel(rawValue: expInt) {
            expansionId = expId
        }
    }
    
}

public struct FFXIVServerLoginResponse {
    public let authOk: Bool
    public let sid: String?
    public let terms: UInt32?
    public let region: UInt32?
    public let etmAdd: UInt32? // ?? wat dis? maintenance maybe?
    public let playable: UInt32?
    public let ps3Package: UInt32?
    public let maxEx: UInt32?
    public let product: UInt32?
    
    public init?(html: String) {
        guard let range = html.range(of: #"(?<=\twindow\.external\.user\(")login=auth.*(?="\);)"#, options: .regularExpression) else {
            return nil
        }
        let string = String(html[range])
        guard let loginVal = string.split(separator: "=").last else {
            return nil
        }
        let pairsArr = loginVal.split(separator: ",", maxSplits: Int.max, omittingEmptySubsequences: true)
        if pairsArr.count % 2 != 0 {
            return nil
        }
        var pairs = [String: String]()
        for i in stride(from: 0, to: pairsArr.count, by: 2) {
            pairs[String(pairsArr[i])] = String(pairsArr[i+1])
        }
        guard let auth = pairs["auth"] else {
            return nil
        }
        authOk = auth == "ok"
        sid = pairs["sid"]
        terms = pairs["terms"] != nil ? UInt32(pairs["terms"]!) : nil
        region = pairs["region"] != nil ? UInt32(pairs["region"]!) : nil
        etmAdd = pairs["etmadd"] != nil ? UInt32(pairs["etmadd"]!) : nil
        playable = pairs["playable"] != nil ? UInt32(pairs["playable"]!) : nil
        ps3Package = pairs["ps3pkg"] != nil ? UInt32(pairs["ps3pkg"]!) : nil
        maxEx = pairs["maxex"] != nil ? UInt32(pairs["maxex"]!) : nil
        product = pairs["product"] != nil ? UInt32(pairs["product"]!) : nil
    }
}

public struct FFXIVLoginCredentials {
    static let squareServer = "https://secure.square-enix.com"
    let username: String
    let password: String
    var oneTimePassword: String? = nil
    
    public init(username: String) {
        self.username = username
        password = ""
        oneTimePassword = nil
    }
    
    public init(username: String, password: String, oneTimePassword: String? = nil) {
        self.username = username
        self.password = password
        self.oneTimePassword = oneTimePassword
    }
    
    static func storedLogin(username: String) -> FFXIVLoginCredentials? {
        let keychain = Keychain(server: squareServer, protocolType: .https)
        // wtf Swift
        guard case let storedPassword?? = (((try? keychain.get(username)) as String??)) else {
            return nil
        }
        return FFXIVLoginCredentials(username: username, password: storedPassword)
    }
    
    static func deleteLogin(username: String) {
        let keychain = Keychain(server: squareServer, protocolType: .https)
        keychain[username] = nil
    }
    
    public func loginData(storedSID: String) -> Data {
        var cmp = URLComponents()
        let queryItems = [
            URLQueryItem(name: "_STORED_", value: storedSID),
            URLQueryItem(name: "sqexid", value: username),
            URLQueryItem(name: "password", value: password),
            URLQueryItem(name: "otppw", value: oneTimePassword ?? "")
        ]
        cmp.queryItems = queryItems
        let str = cmp.percentEncodedQuery!.replacingOccurrences(of: "+", with: "%2B")
        return str.data(using: .utf8)!
    }
    
    public func saveLogin() {
        let keychain = Keychain(server: FFXIVLoginCredentials.squareServer, protocolType: .https)
        keychain[username] = password
    }
    
    public func deleteLogin() {
        FFXIVLoginCredentials.deleteLogin(username: username)
    }
    
    static var accounts: [FFXIVLoginCredentials] {
        let keychain = Keychain(server: squareServer, protocolType: .https)
        return keychain.allKeys().compactMap {storedLogin(username:$0)}.filter {!$0.username.contains(" ")}
    }
    
}
