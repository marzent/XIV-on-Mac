//
//  LoginResult.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 23.05.22.
//

import Foundation
import XIVLauncher

// MARK: - LoginResult
struct LoginResult: Codable {
    let state: Int
    let pendingPatches: [Patch]
    let oauthLogin: OauthLogin
    let uniqueID: String

    enum CodingKeys: String, CodingKey {
        case state = "State"
        case pendingPatches = "PendingPatches"
        case oauthLogin = "OauthLogin"
        case uniqueID = "UniqueId"
    }
    
    init() throws {
        let loginResultJSON = String(cString: tryLoginToGame(Settings.credentials!.username, Settings.credentials!.password, Settings.credentials!.oneTimePassword, Settings.platform == .steam))
        do {
            self = try JSONDecoder().decode(LoginResult.self, from: loginResultJSON.data(using: .utf8)!)
        }
        catch {
            throw XLError.runtimeError(loginResultJSON)
        }
    }
    
    func startGame() throws -> ProcessIdAndHandle {
        let loginResultJSON = String(data: try! JSONEncoder().encode(self), encoding: String.Encoding.utf8)!
        let ret = String(cString: XIVLauncher.startGame(loginResultJSON))
        do {
            return try JSONDecoder().decode(ProcessIdAndHandle.self, from: loginResultJSON.data(using: .utf8)!)
        }
        catch {
            throw XLError.runtimeError(ret)
        }
    }
}

// MARK: - OauthLogin
struct OauthLogin: Codable {
    let sessionID: String
    let region: Int
    let termsAccepted, playable: Bool
    let maxExpansion: Int

    enum CodingKeys: String, CodingKey {
        case sessionID = "SessionId"
        case region = "Region"
        case termsAccepted = "TermsAccepted"
        case playable = "Playable"
        case maxExpansion = "MaxExpansion"
    }
}

// MARK: - ProcessIdAndHandle
struct ProcessIdAndHandle: Codable {
    let pid: Int32
    let handle: Int64
}
