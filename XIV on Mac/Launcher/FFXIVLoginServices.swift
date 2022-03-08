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
import SeeURL


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
    case maintenance
}

private enum FFXIVLoginPageData {
    case success(storedSid: String, cookie: String?)
    case networkError
    case loginError
}


struct FFXIVLogin {
    typealias settings = FFXIVSettings
    static let userAgent = settings.platform == .mac ? "macSQEXAuthor/2.0.0(MacOSX; ja-jp)" : "SQEXAuthor/2.0.0(Windows 6.2; ja-jp; \(uniqueID))"
    static let userAgentPatch = settings.platform == .mac ? "FFXIV-MAC PATCH CLIENT" : "FFXIV PATCH CLIENT"
    let authURL = URL(string: "https://ffxiv-login.square-enix.com/oauth/ffxivarr/login/login.send")!
    
    var loginURL: URL {
        return URL(string: "https://ffxiv-login.square-enix.com/oauth/ffxivarr/login/top?lng=en&rgn=\(settings.region.rawValue)&isft=0&cssmode=1&isnew=1&launchver=3\(settings.platform == .steam ? "&issteam=1" : "")")!
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
            "Referer"        : Frontier.referer.absoluteString,
            "Accept-Encoding": "gzip, deflate",
            //"Accept-Language": ??? TODO: find out how this works and why
            "User-Agent"     : FFXIVLogin.userAgent,
            "Connection"     : "Keep-Alive",
            "Cookie"         : #"_rsid="""#
        ]
        guard let response = HTTPClient.fetch(url: loginURL, headers: headers) else {
            completion(.networkError)
            return
        }
        guard let html = String(data: response.body, encoding: .utf8) else {
            completion(.networkError)
            return
        }
        let recvHeaders = OrderedDictionary(response.headers, uniquingKeysWith: {$1})
        let cookie = recvHeaders["Set-Cookie"]
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
        guard let response = HTTPClient.fetch(url: authURL, headers: headers, postBody: postBody) else {
            completion(.networkError)
            return
        }
        guard let html = String(data: response.body, encoding: .utf8) else {
            completion(.networkError)
            return
        }
        let recvHeaders = OrderedDictionary(response.headers, uniquingKeysWith: {$1})
        let cookie = recvHeaders["Set-Cookie"]
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
    
    fileprivate func getFinalSID(tempSID: String, cookie: String?, completion: @escaping ((FFXIVLoginResult) -> Void)) {
        let headers: OrderedDictionary = [
            "X-Hash-Check": "enabled",
            "User-Agent": FFXIVLogin.userAgentPatch
        ]
        let url = sessionURL.appendingPathComponent(tempSID)
        let postBody = FFXIVApp().versionList(maxEx: settings.expansionId.rawValue).data(using: .utf8)!
        guard let response = HTTPClient.fetch(url: url, headers: headers, postBody: postBody) else {
            completion(.networkError)
            return
        }
        guard let html = String(data: response.body, encoding: .utf8) else {
            completion(.networkError)
            return
        }
        if html.count > 0 {
            if response.statusCode <= 299 {
                completion(.clientUpdate(patches: Patch.parse(patches: html)))
            } else if response.statusCode == 409 { //this means a boot update is required although we checked for it before... install is probably broken af
                completion(.protocolError)
            }
            else {
                completion(.networkError)
            }
            return
        }
        let recvHeaders = OrderedDictionary(response.headers, uniquingKeysWith: {$1})
        if let finalSid = recvHeaders["X-Patch-Unique-Id"] {
            completion(.success(sid: finalSid))
        } else {
            completion(.protocolError)
        }
    }
    
    fileprivate func getBootPatch(completion: @escaping (([Patch]) -> Void))  {
        let headers: OrderedDictionary = [
            "User-Agent": FFXIVLogin.userAgentPatch,
            "Host"      : "patch-bootver.ffxiv.com"
        ]
        guard let response = HTTPClient.fetch(url: patchURL, headers: headers) else {
            completion([])
            return
        }
        if let html = String(data: response.body, encoding: .utf8) {
            completion(Patch.parse(patches: html))
        } else {
            completion([])
        }
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
        guard FFXIVApp().installed else {
            completion(nil)
            return
        }
        let login = FFXIVLogin()
        login.getBootPatch() { patches in
            completion(patches.isEmpty ? nil : patches)
        }
    }
    
    static func login(completion: @escaping ((FFXIVLoginResult) -> Void)) {
        guard FFXIVApp().installed else {
            completion(.noInstall)
            return
        }
        guard let _ = credentials else {
            completion(.incorrectCredentials)
            return
        }
        guard Frontier.checkGate() else {
            completion(.maintenance)
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
        let expansions = FFXIVRepo.expansions(max: maxEx).map({"\($0.rawValue)\t\($0.ver)"})
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
