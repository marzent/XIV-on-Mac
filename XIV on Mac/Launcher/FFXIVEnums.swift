//
//  FFXIVEnums.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 17.03.22.
//

import Foundation

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

public enum FFXIVLoginError: Error {
    case incorrectCredentials
    case noSteamTicket
    case steamUserError
    case notPlayable
    case protocolError
    case networkError
    case noInstall
    case maintenance
    case multibox
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
        case .unexpected(_):
            return NSLocalizedString("UNEXPECTED", comment: "Unexpected Error Description")
        }
    }
}
