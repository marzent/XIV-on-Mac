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
            StartGameOperation.vanilla()
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = "Login system error"
            alert.informativeText = "The login servers did not present the login challenge the way we were expecting. It may have changed on the server. Please check for an update to XIV on Mac to fix this. In the meantime please use the default launcher."
            alert.runModal()
        case .incorrectCredentials:
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = "Incorrect Credentials"
            alert.informativeText = "The login servers did not accept the provided credentials. Please make sure to select the correct license (Windows, Steam or Mac) in Settings."
            alert.runModal()
        case .bootUpdate:
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = "Final Fantasy XIV Needs Repairing!"
            alert.informativeText = "Essential game files are corrupted. Press CMD + R to attempt a repair."
            alert.runModal()
        case .clientUpdate(_):
            ()
        case .networkError:
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = "Network Error"
            alert.informativeText = "Check your internet connection, or try again later. Is FFXIV down?"
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
