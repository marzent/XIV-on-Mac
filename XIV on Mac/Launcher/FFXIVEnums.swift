//
//  FFXIVEnums.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 17.03.22.
//

import Foundation

public enum FFXIVPlatform: UInt8 {
    case windows = 0
    case mac = 1
    case steam = 2
}

public enum FFXIVLanguage: UInt8 {
    case japanese = 0
    case english = 1
    case french = 3
    case german = 2
    
    static func guessFromLocale() -> FFXIVLanguage {
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

public enum XLError: Error {
    case loginError(String)
    case startError(String)
    case runtimeError(String)
    
    var tryMap: Error {
        switch self {
        case .loginError(let errorMessage):
            switch errorMessage {
            case "SteamAPI_Init() failed":
                return FFXIVLoginError.noSteamTicket
            case "ID or password is incorrect.":
                return FFXIVLoginError.incorrectCredentials
            default:
                return self
            }
        case .startError(let errorMessage):
            switch errorMessage {
            default:
                return self
            }
        case .runtimeError(let errorMessage):
            switch errorMessage {
            default:
                return self
            }
        }
    }
}

public enum FFXIVLoginError: Error {
    case incorrectCredentials
    case noSteamTicket
    case steamUserError
    case notPlayable
    case noTerms
    case protocolError
    case networkError
    case noInstall
    case maintenance
    case multibox
    case killswitch
    case unexpected(code: Int)
}

extension FFXIVLoginError: LocalizedError {
    public var failureReason: String? {
        switch self {
        case .incorrectCredentials:
            return NSLocalizedString("INCORRECT_CREDENTIALS_SHORT", comment: "")
        case .noSteamTicket:
            return NSLocalizedString("NO_STEAM_TICKET_SHORT", comment: "")
        case .steamUserError:
            return NSLocalizedString("STEAM_USER_ERROR_SHORT", comment: "")
        case .notPlayable:
            return NSLocalizedString("NOT_PLAYABLE_SHORT", comment: "")
        case .noTerms:
            return NSLocalizedString("NO_TERMS_SHORT", comment: "")
        case .protocolError:
            return NSLocalizedString("PROTOCOL_ERROR_SHORT", comment: "")
        case .networkError:
            return NSLocalizedString("NETWORK_ERROR_SHORT", comment: "")
        case .noInstall:
            return NSLocalizedString("NO_INSTALL_SHORT", comment: "")
        case .maintenance:
            return NSLocalizedString("MAINTENANCE_SHORT", comment: "")
        case .multibox:
            return NSLocalizedString("MULTIBOX_SHORT", comment: "")
        case .killswitch:
            return NSLocalizedString("KILLSWITCH_SHORT", comment: "")
        case .unexpected(_):
            return NSLocalizedString("UNEXPECTED_SHORT", comment: "Unexpected Error Title")
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .incorrectCredentials:
            return NSLocalizedString("INCORRECT_CREDENTIALS", comment: "")
        case .noSteamTicket:
            return NSLocalizedString("NO_STEAM_TICKET", comment: "")
        case .steamUserError:
            return NSLocalizedString("STEAM_USER_ERROR", comment: "")
        case .notPlayable:
            return NSLocalizedString("NOT_PLAYABLE", comment: "")
        case .noTerms:
            return NSLocalizedString("NO_TERMS", comment: "")
        case .protocolError:
            return NSLocalizedString("PROTOCOL_ERROR", comment: "")
        case .networkError:
            return NSLocalizedString("NETWORK_ERROR", comment: "")
        case .noInstall:
            return NSLocalizedString("NO_INSTALL", comment: "")
        case .maintenance:
            return NSLocalizedString("MAINTENANCE", comment: "")
        case .multibox:
            return NSLocalizedString("MULTIBOX", comment: "")
        case .killswitch:
            return NSLocalizedString("KILLSWITCH", comment: "")
        case .unexpected(_):
            return NSLocalizedString("UNEXPECTED", comment: "Unexpected Error Description")
        }
    }
}
