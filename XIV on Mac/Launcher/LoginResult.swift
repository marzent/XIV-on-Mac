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
    let pendingPatches: [Patch]?
    let oauthLogin: OauthLogin?
    let uniqueID: String?

    enum CodingKeys: String, CodingKey {
        case state = "State"
        case pendingPatches = "PendingPatches"
        case oauthLogin = "OauthLogin"
        case uniqueID = "UniqueId"
    }
    
    init(_ repair: Bool) throws {
        let loginResultCString = tryLoginToGame(Settings.credentials!.username, Settings.credentials!.password, Settings.credentials!.oneTimePassword, repair)!
        let loginResultJSON = String(cString: loginResultCString)
        free(UnsafeMutableRawPointer(mutating: loginResultCString))
        do {
            self = try JSONDecoder().decode(LoginResult.self, from: loginResultJSON.data(using: .utf8)!)
        }
        catch {
            throw XLError.loginError(loginResultJSON)
        }
    }
    
    func startGame() throws -> ProcessInformation {
        let loginResultJSON = String(data: try! JSONEncoder().encode(self), encoding: String.Encoding.utf8)!
        let processInformationCString = XIVLauncher.startGame(loginResultJSON)!
        let processInformationJSON = String(cString: processInformationCString)
        free(UnsafeMutableRawPointer(mutating: processInformationCString))
        do {
            return try JSONDecoder().decode(ProcessInformation.self, from: processInformationJSON.data(using: .utf8)!)
        }
        catch {
            throw XLError.startError(processInformationJSON)
        }
    }
    
    func repairGame() -> String {
        let loginResultJSON = String(data: try! JSONEncoder().encode(self), encoding: String.Encoding.utf8)!
        let repairResultCString = XIVLauncher.repairGame(loginResultJSON)!
        let repairResult = String(cString: repairResultCString)
        free(UnsafeMutableRawPointer(mutating: repairResultCString))
        return repairResult
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

// MARK: - ProcessInformation
struct ProcessInformation: Codable {
    let pid: Int32
    let handle: Int64
    
    var exitCode: Int32 {
        getExitCode(pid)
    }
}
