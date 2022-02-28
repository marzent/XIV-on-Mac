//
//  FFXIVLoginServices.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Foundation
import Security
import KeychainAccess
import CryptoKit
import AppKit
import OrderedCollections


public enum FFXIVPlatform: UInt32 {
    case windows = 0
    case mac = 1
    case steam = 2
}

public enum FFXIVExpansionLevel: UInt32 {
    case aRealmReborn = 0
    case heavensward = 1
    case stormblood = 2
    case shadowbringers = 3
    case endwalker = 4
}

public enum FFXIVRegion: UInt32 {
    case japanese = 0
    case english = 2
    case french = 1
    case german = 3
    
    static func guessFromLocale() -> FFXIVRegion {
        switch Locale.current.languageCode {
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
    
    var language: FFXIVLanguage {
        switch self {
        case .english:
            return .english
        case .french:
            return .french
        case .german:
            return .german
        case .japanese:
            return .japanese
        }
    }
}

public enum FFXIVLanguage: UInt32 {
    case japanese = 0
    case english = 1
    case french = 3
    case german = 2
    
    var code: String {
        switch self {
        case .english:
            switch TimeZone.current.identifier.split(separator: "/").first ?? "" {
            case "America", "Antarctica", "Pacific":
                return "en-us"
            default:
                return "en-gb"
            }
        case .french:
            return "fr"
        case .german:
            return "de"
        case .japanese:
            return "ja"
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
    case success(sid: String)
    case bootUpdate(patches: [Patch])
    case clientUpdate(patches: [Patch])
    case incorrectCredentials
    case protocolError
    case networkError
    case noInstall
}

private enum FFXIVLoginPageData {
    case success(storedSid: String, cookie: String?)
    case networkError
    case loginError
}

private class FFXIVSSLDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Always trust the Square Enix server. Yep, this can totally make us vulnerable to MITM, but you can
        // blame SE for not setting up SSL correctly! The REAL launcher is vulnerable to MITM.
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}

struct FFXIVLogin {
    typealias settings = FFXIVSettings
    static let userAgent = settings.platform == .mac ? "macSQEXAuthor/2.0.0(MacOSX; ja-jp)" : "SQEXAuthor/2.0.0(Windows 6.2; ja-jp; \(uniqueID))"
    static let userAgentPatch = settings.platform == .mac ? "FFXIV-MAC PATCH CLIENT" : "FFXIV PATCH CLIENT"
    fileprivate let sslDelegate = FFXIVSSLDelegate()
    let authURL = URL(string: "https://ffxiv-login.square-enix.com/oauth/ffxivarr/login/login.send")!
    
    var loginURL: URL {
        return URL(string: "https://ffxiv-login.square-enix.com/oauth/ffxivarr/login/top?lng=en&rgn=\(settings.region.rawValue)&isft=0&cssmode=1&isnew=1&launchver=3\(settings.platform == .steam ? "&issteam=1" : "")")!
    }
    
    var frontierURL: URL {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd-HH"
        return URL(string: "https://launcher.finalfantasyxiv.com/v600/index.html?rc_lang=\(settings.language.code)&time=\(dateFormatter.string(from: Date()))")!
    }
    
    var patchURL: URL {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm"
        return URL(string: "http://patch-bootver.ffxiv.com/http/win32/ffxivneo_release_boot/\(FFXIVRepo.boot.ver)/?time=\(dateFormatter.string(from: Date()))")! //yes http this is not a mistake
    }
    
    var sessionURL: URL {
        return URL(string: "https://patch-gamever.ffxiv.com/http/win32/ffxivneo_release_game/\(FFXIVRepo.game.ver)")!
    }
    
    fileprivate func getStored(completion: @escaping ((FFXIVLoginPageData) -> Void)) {
        let headers: OrderedDictionary = [
            "Accept"         : "image/gif, image/jpeg, image/pjpeg, application/x-ms-application, application/xaml+xml, application/x-ms-xbap, */*",
            "Referer"        : frontierURL.absoluteString,
            "Accept-Encoding": "gzip, deflate",
            //"Accept-Language": ??? TODO: find out how this works and why
            "User-Agent"     : FFXIVLogin.userAgent,
            "Connection"     : "Keep-Alive",
            "Cookie"         : #"_rsid="""#
        ]
        fetch(headers: headers, url: loginURL, postBody: nil) { body, response in
            guard let html = body else {
                completion(.networkError)
                return
            }
            let cookie = response?.allHeaderFields["Set-Cookie"] as? String
            let op = StoredParseOperation(html: html)
            let queue = OperationQueue()
            op.completionBlock = {
                DispatchQueue.main.async {
                    guard case let .some(HTMLParseResult.result(result)) = op.result else {
                        completion(.loginError)
                        return
                    }
                    completion(.success(storedSid: result, cookie: cookie))
                }
            }
            queue.addOperation(op)
        }
    }
    
    fileprivate func getTempSID(storedSID: String, cookie: String?, completion: @escaping ((FFXIVLoginResult) -> Void)) {
        let headers: OrderedDictionary = [
            "Accept"         : "image/gif, image/jpeg, image/pjpeg, application/x-ms-application, application/xaml+xml, application/x-ms-xbap, */*",
            "Referer"        : loginURL.absoluteString,
            //"Accept-Language": ??? TODO: find out how this works and why
            "User-Agent"     : FFXIVLogin.userAgent,
            "Accept-Encoding": "gzip, deflate",
            "Host"           : "ffxiv-login.square-enix.com",
            "Connection"     : "Keep-Alive",
            "Cache-Control"  : "no-cache",
            "Cookie"         : cookie ?? #"_rsid="""#
        ]
        let postBody = settings.credentials!.loginData(storedSID: storedSID)
        fetch(headers: headers, url: authURL, postBody: postBody) { body, response in
            guard let html = body else {
                completion(.networkError)
                return
            }
            let cookie = response?.allHeaderFields["Set-Cookie"] as? String
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
                    settings.update(from: parsedResult)
                    self.getFinalSID(tempSID: sid, cookie: cookie, completion: completion)
                }
            }
            queue.addOperation(op)
        }
    }
    
    fileprivate func getFinalSID(tempSID: String, cookie: String?, completion: @escaping ((FFXIVLoginResult) -> Void)) {
        let headers: OrderedDictionary = [
            "X-Hash-Check": "enabled",
            "User-Agent": FFXIVLogin.userAgentPatch
        ]
        let postBody = FFXIVApp().versionList(maxEx: settings.expansionId.rawValue).data(using: .utf8)
        fetch(headers: headers, url: sessionURL.appendingPathComponent(tempSID), postBody: postBody) { body, response in
            if let unexpectedResponseBody = body, unexpectedResponseBody.count > 0 {
                let status = response?.statusCode ?? 404
                if status <= 299 {
                    completion(.clientUpdate(patches: Patch.parse(patches: unexpectedResponseBody)))
                } else if status == 409 { //this means a boot update is required although we checked for it before... install is probably broken af
                    completion(.protocolError)
                }
                else {
                    completion(.networkError)
                }
                return
            }

            // Apple changed allHeaderFields in newer SDKs to "canonicalize" headers. So on some OSes it'll be lowercase and others it won't... thanks.
            if let finalSid = response?.allHeaderFields["X-Patch-Unique-Id"] as? String {
                completion(.success(sid: finalSid))
            } else if let finalSid = response?.allHeaderFields["x-patch-unique-id"] as? String {
                completion(.success(sid: finalSid))
            } else {
                completion(.protocolError)
            }
        }
    }
    
    fileprivate func getBootPatch(completion: @escaping (([Patch]) -> Void))  {
        let headers: OrderedDictionary = [
            "User-Agent": FFXIVLogin.userAgentPatch,
            "Host"      : "patch-bootver.ffxiv.com"
        ]
        fetch(headers: headers, url: patchURL, postBody: nil) { body, response in
            guard let html = body else {
                completion([])
                return
            }
            completion(Patch.parse(patches: html))
        }
    }
    
    fileprivate func fetch(headers: OrderedDictionary<String, String>, url: URL, postBody: Data?, completion: @escaping ((_ body: String?, _ response: HTTPURLResponse?) -> Void)) {
        let session = URLSession(configuration: .default, delegate: sslDelegate, delegateQueue: nil)
        var req = URLRequest(url: url)
        for (hdr, val) in headers {
            req.addValue(val, forHTTPHeaderField: hdr)
        }
        if let uploadedBody = postBody {
            req.httpBody = uploadedBody
            req.httpMethod = "POST"
        }
        let task = session.dataTask(with: req) { (data, resp, err) in
            guard let response = resp as? HTTPURLResponse else {
                completion(nil, nil)
                return
            }
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
    
    static var uniqueID: String {
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
    
    static func checkBoot(completion: @escaping (([Patch]?) -> Void)) {
        if !FFXIVApp().installed {
            completion(nil)
            return
        }
        let login = FFXIVLogin()
        login.getBootPatch() { patches in
            if !patches.isEmpty {
                completion(patches)
            }
            else {
                completion(nil)
            }
        }
    }
    
    static func login(completion: @escaping ((FFXIVLoginResult) -> Void)) {
        if !FFXIVApp().installed {
            completion(.noInstall)
            return
        }
        if credentials == nil {
            completion(.incorrectCredentials)
            return
        }
        let login = FFXIVLogin()
        login.getStored() { result in
            switch result {
            case .networkError:
                completion(.networkError)
            case .loginError:
                completion(.protocolError)
            case .success(let storedSid, let cookie):
                login.getTempSID(storedSID: storedSid, cookie: cookie, completion: completion)
            }
        }
    }
    
    static func update(from response: FFXIVServerLoginResponse) {
        if let rgnInt = response.region, let rgn = FFXIVRegion(rawValue: rgnInt) {
            region = rgn
        }
        if let expInt = response.maxEx, let expId = FFXIVExpansionLevel(rawValue: expInt) {
            expansionId = expId
        }
    }
    
}

public struct FFXIVApp {
    let bootRepoURL, bootExeURL, bootExe64URL, launcherExeURL, launcherExe64URL, updaterExeURL, updaterExe64URL: URL
    let gameRepoURL, dx9URL, dx11URL, sqpackFolderURL: URL
    private let bootFiles: [URL]
    
    init() {
        bootRepoURL = FFXIVSettings.gamePath.appendingPathComponent("boot")
        bootExeURL = bootRepoURL.appendingPathComponent("ffxivboot.exe")
        bootExe64URL = bootRepoURL.appendingPathComponent("ffxivboot64.exe")
        launcherExeURL = bootRepoURL.appendingPathComponent("ffxivlauncher.exe")
        launcherExe64URL = bootRepoURL.appendingPathComponent("ffxivlauncher64.exe")
        updaterExeURL = bootRepoURL.appendingPathComponent("ffxivupdater.exe")
        updaterExe64URL = bootRepoURL.appendingPathComponent("ffxivupdater64.exe")
        
        gameRepoURL = FFXIVSettings.gamePath.appendingPathComponent("game")
        dx9URL = gameRepoURL.appendingPathComponent("ffxiv.exe")
        dx11URL = gameRepoURL.appendingPathComponent("ffxiv_dx11.exe")
        sqpackFolderURL = gameRepoURL.appendingPathComponent("sqpack")
        
        bootFiles = [bootExeURL, bootExe64URL, launcherExeURL, launcherExe64URL, updaterExeURL, updaterExe64URL]
    }
    
    var installed: Bool {
        bootFiles.allSatisfy({FileManager.default.fileExists(atPath: $0.path)})
    }
    
    var bootHash: String {
        bootFiles.map({(try? FFXIVApp.hashSegment(file: $0)) ?? ""}).joined(separator: ",")
    }

    func versionList(maxEx: UInt32) -> String {
        let expansions = FFXIVRepo.array(maxEx).dropFirst(2).map({"\($0.rawValue)\t\($0.ver)"})
        return "\(FFXIVRepo.boot.ver)=\(bootHash)\n\(expansions.joined(separator: "\n"))"
    }
    
    private static func hashSegment(file: URL) throws -> String {
        let (hash, len) = try FFXIVApp.sha1(file: file)
        return "\(file.lastPathComponent)/\(len)/\(hash)"
    }
    
    private static func sha1(file: URL) throws -> (String, Int) {
        let data = try Data.init(contentsOf: file)
        let digest = Insecure.SHA1.hash(data: data)
        return (digest.hexStr, data.count)
    }
}

extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var hexStr: String {
        var string = ""
        for byte in self.bytes {
            string += String(format: "%02x", byte)
        }
        return string
    }
}
