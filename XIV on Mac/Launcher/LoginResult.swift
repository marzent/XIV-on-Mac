//
//  LoginResult.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 23.05.22.
//

import Foundation
import XIVLauncher
import CompatibilityTools

// MARK: - LoginResult

struct LoginResult: Codable {
    private let _state: Int
    let pendingPatches: [Patch]?
    let oauthLogin: OauthLogin?
    let uniqueID: String?

    enum CodingKeys: String, CodingKey {
        case _state = "State"
        case pendingPatches = "PendingPatches"
        case oauthLogin = "OauthLogin"
        case uniqueID = "UniqueId"
    }

    enum LoginState: Int {
        case Unknown
        case Ok
        case NeedsPatchGame
        case NeedsPatchBoot
        case NoService
        case NoTerms
        case NoLogin
    }

    var state: LoginState {
        LoginState(rawValue: _state) ?? .Unknown
    }

    init(_ repair: Bool, recaptchaToken: String? = nil) throws {
        let loginResultCString = tryLoginToGame(
            Settings.credentials!.username, Settings.credentials!.password,
            Settings.credentials!.oneTimePassword, recaptchaToken ?? "", repair)!
        let loginResultJSON = String(cString: loginResultCString)
        free(UnsafeMutableRawPointer(mutating: loginResultCString))
        do {
            self = try JSONDecoder().decode(
                LoginResult.self, from: loginResultJSON.data(using: .utf8)!)
        } catch {
            throw XLError.loginError(loginResultJSON).tryMap
        }
    }

    var dalamudInstallState: Dalamud.InstallState {
        Dalamud.InstallState(rawValue: getDalamudInstallState()) ?? .failed
    }

    func startGame(_ _dalamudOk: Bool) throws -> ProcessInformation {
        // Update XL_DXMT_ENABLED environment variable before starting game
        // This ensures the C# layer uses the current backend setting
        addEnvironmentVariable("XL_DXMT_ENABLED", Settings.dxmtEnabled ? "1" : "0")
        
        let loginResultJSON = String(
            data: try! JSONEncoder().encode(self),
            encoding: String.Encoding.utf8)!
        let processInformationCString = XIVLauncher.startGame(
            loginResultJSON, _dalamudOk)!
        let processInformationJSON = String(cString: processInformationCString)
        free(UnsafeMutableRawPointer(mutating: processInformationCString))
        do {
            return try JSONDecoder().decode(
                ProcessInformation.self,
                from: processInformationJSON.data(using: .utf8)!)
        } catch {
            throw XLError.startError(processInformationJSON).tryMap
        }
    }

    func repairGame() -> String {
        let loginResultJSON = String(
            data: try! JSONEncoder().encode(self),
            encoding: String.Encoding.utf8)!
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

    enum CodingKeys: String, CodingKey {
        case pid = "Pid"
        case handle = "Handle"
    }

    var exitCode: Int32 {
        getExitCode(pid)
    }
}
