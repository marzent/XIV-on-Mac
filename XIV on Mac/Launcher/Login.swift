//
//  Login.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Cocoa

class LoginOperation: AsyncOperation {
    var loginResult: FFXIVLoginResult?
    
    override func main() {
        FFXIVSettings.login() { result in
            DispatchQueue.main.async {
                self.handleResult(result: result)
            }
        }
    }
    
    func handleResult(result: FFXIVLoginResult) {
        loginResult = result
        switch result {
        case .protocolError:
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = "Login system error"
            alert.informativeText = "The login servers did not accept the request. Please make sure to have an active subsricption and select the correct license (Windows, Steam or Mac) in Settings."
            alert.runModal()
        case .incorrectCredentials:
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = "Incorrect Credentials"
            alert.informativeText = "The login servers did not accept the provided credentials. "
            alert.runModal()
        case .noSteamTicket:
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = "Could not connect to Steam"
            alert.informativeText = "XIV on Mac could not obtain a valid Steam Ticket for Final Fantasy XIV. Make sure Steam is runnning, you are logged in and that you linked your Steam Account."
            alert.runModal()
        case .steamUserError:
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = "Steam Error"
            alert.informativeText = "Ther is a mismatch between the provided username and Steam account."
            alert.runModal()
        case .bootUpdate:
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = "Final Fantasy XIV Needs Repairing!"
            alert.informativeText = "Essential game files are corrupted. Press CMD + R to attempt a repair."
            alert.runModal()
        case .clientUpdate(_):
            print("Starting Patcher...")
        case .networkError:
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = "Network Error"
            alert.informativeText = "Check your internet connection, or try again later. Is FFXIV down?"
            alert.runModal()
        case .maintenance:
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = "Maintenance in progress"
            alert.informativeText = "Please wait until maintenance finishes before logging in."
            alert.runModal()
        case .noInstall:
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = "Final Fantasy XIV is not installed!"
            alert.informativeText = "Essential game files could not be found.\nStarting Installer..."
            alert.runModal()
            NotificationCenter.default.post(name: .startInstall, object: nil)
        case .success(_):
            print("Login Success!")
        }
        
        state = .finished
    }
}
