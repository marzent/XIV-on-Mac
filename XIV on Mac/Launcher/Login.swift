//
//  Login.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Cocoa

class LoginOperation: AsyncOperation {
    let settings: FFXIVSettings
    var loginResult: FFXIVLoginResult?
    
    init(settings: FFXIVSettings) {
        self.settings = settings
    }
    
    override func main() {
        settings.login() { result in
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
            alert.informativeText = "The login servers did not present the login challenge the way we were expecting. " +
                "It may have changed on the server. Please check for an update to LaunchXIV to fix this. In the meantime " +
            "please use the default launcher."
            alert.runModal()
            NSApp.terminate(nil)
        case .incorrectCredentials:
            // Let the caller handle it
            break
        case .clientUpdate:
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = "Final Fantasy XIV Needs Updating!"
            alert.informativeText = "LaunchXIV cannot patch Final Fantasy XIV. Please use the standard launcher to patch."
            alert.runModal()
            NSApp.terminate(nil)
        case .networkError:
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = "Network Error"
            alert.informativeText = "Check your internet connection, or try again later. Is FFXIV down?"
            alert.runModal()
            NSApp.terminate(nil)
        case .success(_, let updatedSettings):
            // These settings are provably correct, definitely save them
            updatedSettings.serialize()
        }
        
        state = .finished
    }
}
