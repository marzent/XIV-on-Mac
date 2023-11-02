//
//  LoginCredentials.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Foundation
import KeychainAccess
import OrderedCollections

public struct LoginCredentials {
    static let squareServer = "https://secure.square-enix.com"
    let username: String
    let password: String
    var oneTimePassword: String?
    
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
    
    static func storedLogin(username: String) -> LoginCredentials? {
        let keychain = Keychain(server: squareServer, protocolType: .https)
        guard case let storedPassword?? = ((try? keychain.get(username)) as String??) else {
            return nil
        }
        return LoginCredentials(username: username, password: storedPassword)
    }
    
    static func deleteLogin(username: String) {
        let keychain = Keychain(server: squareServer, protocolType: .https)
        keychain[username] = nil
    }
    
    public func saveLogin() {
        let keychain = Keychain(server: LoginCredentials.squareServer, protocolType: .https)
        keychain[username] = password
    }
    
    public func deleteLogin() {
        LoginCredentials.deleteLogin(username: username)
    }
    
    static var accounts: [LoginCredentials] {
        let keychain = Keychain(server: squareServer, protocolType: .https)
        return keychain.allKeys().compactMap { storedLogin(username: $0) }.filter { !$0.username.contains(" ") }
    }
}
