//
//  FFXIVLoginServices.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Foundation
import Security
import KeychainAccess
import CommonCrypto
import AppKit


public enum FFXIVExpansionLevel: UInt32 {
    case aRealmReborn = 0
    case heavensward = 1
    case stormblood = 2
    case shadowbringers = 3
    case endwalker = 4
}

public enum FFXIVRegion: UInt32 {
    case japanese = 0
    case english = 3
    case french = 1
    case german = 2
    
    static func guessFromLocale() -> FFXIVRegion {
        switch NSLocale.current.languageCode {
        case "ja"?:
            return .japanese
        case "en"?:
            return .english
        case "fr"?:
            return .french
        case "de"?:
            return .german
        default:
            return .english
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
    
    public init?(string: String) {
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
    let username: String
    let password: String
    var oneTimePassword: String? = nil
    
    public let port = 80
    public let server = "secure.square-enix.com"
    
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
        let keychain = Keychain(server: "https://secure.square-enix.com", protocolType: .https)
        // wtf Swift
        guard case let storedPassword?? = (((try? keychain.get(username)) as String??)) else {
            return nil
        }
        return FFXIVLoginCredentials(username: username, password: storedPassword)
    }
    
    static func deleteLogin(username: String) {
        let keychain = Keychain(server: "https://secure.square-enix.com", protocolType: .https)
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
        let str = cmp.percentEncodedQuery!
        return str.data(using: .utf8)!
    }
    
    public func saveLogin() {
        let keychain = Keychain(server: "https://secure.square-enix.com", protocolType: .https)
        keychain[username] = password
    }
    
    public func deleteLogin() {
        FFXIVLoginCredentials.deleteLogin(username: username)
    }
}

public enum FFXIVLoginResult {
    case success(sid: String, updatedSettings: FFXIVSettings)
    case clientUpdate
    case incorrectCredentials
    case protocolError
    case networkError
}

private enum FFXIVLoginPageData {
    case success(storedSid: String, cookie: String?)
    case error
}

public struct FFXIVSettings {
    public var credentials: FFXIVLoginCredentials?
    public var expansionId: FFXIVExpansionLevel = .aRealmReborn
    public var dalamud: Bool = false
    public var usesOneTimePassword: Bool = false
    public var appPath: URL?
    public var region: FFXIVRegion = FFXIVRegion.guessFromLocale()
    
    static func storedSettings(storage: UserDefaults = UserDefaults.standard) -> FFXIVSettings {
        var settings = FFXIVSettings()
        if let storedUsername = storage.string(forKey: "username") {
            let login = FFXIVLoginCredentials.storedLogin(username: storedUsername)
            settings.credentials = login
        }
        if let path = storage.string(forKey: "appPath") {
            settings.appPath = URL(fileURLWithPath: path)
        }
        if let expansionId = FFXIVExpansionLevel(rawValue: UInt32(storage.integer(forKey: "expansionId"))) {
            settings.expansionId = expansionId
        }
        if let region = FFXIVRegion(rawValue: UInt32(storage.integer(forKey: "region"))) {
            settings.region = region
        }
        settings.dalamud = storage.bool(forKey: "dalamud")
        settings.usesOneTimePassword = storage.bool(forKey: "usesOneTimePassword")
        return settings
    }
    
    func serialize(into storage: UserDefaults = UserDefaults.standard) {
        if let username = credentials?.username {
            storage.set(username, forKey: "username")
        }
        storage.set(expansionId.rawValue, forKey: "expansionId")
        storage.set(dalamud, forKey: "dalamud")
        storage.set(usesOneTimePassword, forKey: "usesOneTimePassword")
        storage.set(appPath?.path, forKey: "appPath")
        storage.set(region.rawValue, forKey: "region")
        storage.synchronize()
        if let creds = credentials {
            creds.saveLogin()
        }
    }
    
    public func login(completion: @escaping ((FFXIVLoginResult) -> Void)) {
        print(FFXIVApp().versionHash)
        if credentials == nil {
            completion(.incorrectCredentials)
            return
        }
        guard let login = FFXIVLogin(settings: self) else {
            return
        }
        login.getStored() { result in
            switch result {
            case .error:
                completion(.protocolError)
            case .success(let storedSid, let cookie):
                login.getTempSID(storedSID: storedSid, cookie: cookie, completion: completion)
            }
        }
    }
    
    public mutating func update(from response: FFXIVServerLoginResponse) {
        if let rgnInt = response.region, let rgn = FFXIVRegion(rawValue: rgnInt) {
            region = rgn
        }
        if let expInt = response.maxEx, let expId = FFXIVExpansionLevel(rawValue: expInt) {
            expansionId = expId
        }
    }
}

private class FFXIVSSLDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Always trust the Square Enix server. Yep, this can totally make us vulnerable to MITM, but you can
        // blame SE for not setting up SSL correctly! The REAL launcher is vulnerable to MITM.
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}

private struct FFXIVLogin {
    static let userAgent = Util.macLicense ? "macSQEXAuthor/2.0.0(MacOSX; ja-jp)" : "SQEXAuthor/2.0.0(Windows 6.2; ja-jp; \(uniqueID))"
    static let userAgentPatch = Util.macLicense ? "FFXIV-MAC PATCH CLIENT" : "FFXIV PATCH CLIENT"
    static let authURL = URL(string: "https://ffxiv-login.square-enix.com/oauth/ffxivarr/login/login.send")!
    
    static let loginHeaders = [
        "User-Agent": userAgent
    ]
    
    static let authHeaders = [
        "User-Agent": userAgent,
        "Content-Type": "application/x-www-form-urlencoded"
    ]
    
    static let sessionHeaders = [
        "User-Agent": userAgentPatch,
        "Content-Type": "application/x-www-form-urlencoded",
        "X-Hash-Check": "enabled"
    ]
    
    
    static let versionHeaders = [
        "User-Agent": userAgentPatch
    ]
    
    var loginURL: URL {
        return URL(string: "https://ffxiv-login.square-enix.com/oauth/ffxivarr/login/top?lng=en&rgn=\(settings.region.rawValue)&isft=0&cssmode=1&isnew=1&launchver=3")!
    }
    
    var sessionURL: URL {
        return URL(string: "https://patch-gamever.ffxiv.com/http/win32/ffxivneo_release_game/\(app.gameVer)")!
    }
    
    let settings: FFXIVSettings
    let app: FFXIVApp
    let sslDelegate = FFXIVSSLDelegate()
    
    init?(settings: FFXIVSettings) {
        self.settings = settings
        app = FFXIVApp()
    }
    
    fileprivate func getStored(completion: @escaping ((FFXIVLoginPageData) -> Void)) {
        fetch(headers: FFXIVLogin.loginHeaders, url: loginURL, postBody: nil) { body, response in
            guard let html = body else {
                completion(.error)
                return
            }
            let cookie = response.allHeaderFields["Set-Cookie"] as? String
            let op = StoredParseOperation(html: html)
            let queue = OperationQueue()
            op.completionBlock = {
                DispatchQueue.main.async {
                    guard case let .some(HTMLParseResult.result(result)) = op.result else {
                        completion(.error)
                        return
                    }
                    completion(.success(storedSid: result, cookie: cookie))
                }
            }
            queue.addOperation(op)
        }
    }
    
    fileprivate func getTempSID(storedSID: String, cookie: String?, completion: @escaping ((FFXIVLoginResult) -> Void)) {
        var headers = FFXIVLogin.authHeaders
        if let cookie = cookie {
            headers["Cookie"] = cookie
        }
        headers["Referer"] = loginURL.absoluteString
        let postBody = settings.credentials!.loginData(storedSID: storedSID)
        fetch(headers: headers, url: FFXIVLogin.authURL, postBody: postBody) { body, response in
            guard let html = body else {
                completion(.protocolError)
                return
            }
            let cookie = response.allHeaderFields["Set-Cookie"] as? String
            let op = SidParseOperation(html: html)
            let queue = OperationQueue()
            op.completionBlock = {
                DispatchQueue.main.async {
                    guard case let .some(HTMLParseResult.result(result)) = op.result else {
                        completion(.protocolError)
                        return
                    }
                    guard let parsedResult = FFXIVServerLoginResponse(string: result) else {
                        completion(.protocolError)
                        return
                    }
                    if !parsedResult.authOk {
                        completion(.incorrectCredentials)
                        return
                    }
                    guard let sid = parsedResult.sid else {
                        completion(.protocolError)
                        return
                    }
                    var updatedSettings = self.settings
                    updatedSettings.update(from: parsedResult)
                    self.getFinalSID(tempSID: sid, cookie: cookie, updatedSettings: updatedSettings, completion: completion)
                }
            }
            queue.addOperation(op)
        }
    }
    
    fileprivate func getFinalSID(tempSID: String, cookie: String?, updatedSettings: FFXIVSettings, completion: @escaping ((FFXIVLoginResult) -> Void)) {
        let headers = FFXIVLogin.sessionHeaders

        var url = sessionURL
        url = url.appendingPathComponent(tempSID)
        let postBody = app.versionList(maxEx: updatedSettings.expansionId.rawValue).data(using: .utf8)
        fetch(headers: headers, url: url, postBody: postBody) { body, response in
            if let unexpectedResponseBody = body, unexpectedResponseBody.count > 0 {
                if (response.statusCode <= 299) {
                    completion(.clientUpdate)
                } else {
                    completion(.networkError)
                }
                return
            }

            // Apple changed allHeaderFields in newer SDKs to "canonicalize" headers. So on some OSes it'll be lowercase and others it won't... thanks.
            if let finalSid = response.allHeaderFields["X-Patch-Unique-Id"] as? String {
                completion(.success(sid: finalSid, updatedSettings: updatedSettings))
            } else if let finalSid = response.allHeaderFields["x-patch-unique-id"] as? String {
                completion(.success(sid: finalSid, updatedSettings: updatedSettings))
            } else {
                completion(.protocolError)
            }
        }
    }
    
    fileprivate func fetch(headers: [String: String], url: URL, postBody: Data?, completion: @escaping ((_ body: String?, _ response: HTTPURLResponse) -> Void)) {
        let session = URLSession(configuration: .default, delegate: sslDelegate, delegateQueue: nil)
        let req = NSMutableURLRequest(url: url)
        for (hdr, val) in headers {
            req.addValue(val, forHTTPHeaderField: hdr)
        }
        if let uploadedBody = postBody {
            req.httpBody = uploadedBody
            req.httpMethod = "POST"
        }
        let task = session.dataTask(with: req as URLRequest) { (data, resp, err) in
            let response = resp as! HTTPURLResponse
            guard let data = data else {
                completion(nil, response)
                return
            }
            if response.statusCode != 200 || err != nil || data.count == 0 {
                completion(nil, response)
                return
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                completion(nil, response)
                return
            }
            completion(html, response)
        }
        task.resume()
    }
    
    static private var uniqueID: String {
          let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice") )

          guard platformExpert > 0 else {
            return "ecf4a84335"
          }

          guard let serialNumber = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String) else {
            return "ecf4a84335"
          }


          IOObjectRelease(platformExpert)

        return String(serialNumber.lowercased().prefix(10))
    }
}

public struct FFXIVApp {
    let bootExeURL: URL
    let bootExe64URL: URL
    let bootVersionURL: URL
    let launcherExeURL: URL
    let launcherExe64URL: URL
    let updaterExeURL: URL
    let updaterExe64URL: URL
    let dx9URL: URL
    let dx11URL: URL
    let gameVersionURL: URL
    let sqpackFolderURL: URL
    
    init() {

        let ffxiv = Wine.prefix
            .appendingPathComponent("drive_c")
            .appendingPathComponent("Program Files (x86)")
            .appendingPathComponent("SquareEnix")
            .appendingPathComponent("FINAL FANTASY XIV - A Realm Reborn")

        
        let boot = ffxiv.appendingPathComponent("boot")
        bootExeURL = boot.appendingPathComponent("ffxivboot.exe")
        bootExe64URL = boot.appendingPathComponent("ffxivboot64.exe")
        bootVersionURL = boot.appendingPathComponent("ffxivboot.ver")
        launcherExeURL = boot.appendingPathComponent("ffxivlauncher.exe")
        launcherExe64URL = boot.appendingPathComponent("ffxivlauncher64.exe")
        updaterExeURL = boot.appendingPathComponent("ffxivupdater.exe")
        updaterExe64URL = boot.appendingPathComponent("ffxivupdater64.exe")
        
        let game = ffxiv.appendingPathComponent("game")
        dx9URL = game.appendingPathComponent("ffxiv.exe")
        dx11URL = game.appendingPathComponent("ffxiv_dx11.exe")
        gameVersionURL = game.appendingPathComponent("ffxivgame.ver")
        sqpackFolderURL = game.appendingPathComponent("sqpack")
    }
    
    var bootVer: String {
        let data = try! Data.init(contentsOf: bootVersionURL)
        return String(data: data, encoding: .utf8)!
    }
    
    var gameVer: String {
        let data = try! Data.init(contentsOf: gameVersionURL)
        return String(data: data, encoding: .utf8)!
    }
    
    var versionHash: String {
        let segments = [
            FFXIVApp.hashSegment(file: bootExeURL),
            FFXIVApp.hashSegment(file: bootExe64URL),
            FFXIVApp.hashSegment(file: launcherExeURL),
            FFXIVApp.hashSegment(file: launcherExe64URL),
            FFXIVApp.hashSegment(file: updaterExeURL),
            FFXIVApp.hashSegment(file: updaterExe64URL),
        ]
        return segments.joined(separator: ",")
    }

    func sqpackVer(expansion: String) -> String {
        let url = sqpackFolderURL
            .appendingPathComponent(expansion)
            .appendingPathComponent("\(expansion).ver")

        let data = try! Data.init(contentsOf: url)
        return String(data: data, encoding: .utf8)!
    }

    func versionList(maxEx: UInt32) -> String {
        let exs = stride(from: 1, through: maxEx, by: 1).map({"ex\($0)"})
        let versions = exs.map({"\($0)\t\(sqpackVer(expansion: $0))"})
        let versionList = "\(bootVer)=\(versionHash)\n\(versions.joined(separator: "\n"))"
        return versionList
    }
    
    private static func hashSegment(file: URL) -> String {
        let (hash, len) = FFXIVApp.sha1(file: file)
        return "\(file.lastPathComponent)/\(len)/\(hash)"
    }
    
    private static func sha1(file: URL) -> (String, Int) {
        let data = try! Data.init(contentsOf: file)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Void in
            CC_SHA1(bytes.baseAddress, UInt32(data.count), &hash)
        }

        var string = ""
        for byte in hash {
            string += String(format: "%02x", byte)
        }
        return (string, data.count)
    }
}
