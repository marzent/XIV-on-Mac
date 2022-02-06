//
//  LaunchController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Cocoa

class LaunchController: NSViewController {
    
    var loginSheetWinController: NSWindowController?
    
    @IBOutlet private var loginButton: NSButton!
    @IBOutlet private var userField: NSTextField!
    @IBOutlet private var passwdField: NSTextField!
    @IBOutlet private var otpField: NSTextField!
    
    var settings: FFXIVSettings = FFXIVSettings()
    
    override func viewDidAppear() {
        super.viewDidAppear()
        update(FFXIVSettings.storedSettings())
        loginSheetWinController = storyboard?.instantiateController(withIdentifier: "LoginSheet") as? NSWindowController
        settings.dalamud = true
        view.window?.isMovableByWindowBackground = true
    }
    
    private func update(_ settings: FFXIVSettings) {
        settings.serialize()
        self.settings = settings
        userField.stringValue = settings.credentials?.username ?? ""
        passwdField.stringValue = settings.credentials?.password ?? ""
    }
    
    @IBAction func doLogin(_ sender: Any) {
        view.window?.beginSheet(loginSheetWinController!.window!)
        settings.credentials = FFXIVLoginCredentials(username: userField.stringValue, password: passwdField.stringValue, oneTimePassword: otpField.stringValue)
        doLogin()
    }
    
    func doLogin() {
        let queue = OperationQueue()
        let op = LoginOperation(settings: settings)
        op.completionBlock = {
            switch op.loginResult {
            case .success(let sid, let updatedSettings)?:
                DispatchQueue.main.async {
                    self.startGame(sid: sid, settings: updatedSettings)
                }
            case .incorrectCredentials:
                DispatchQueue.main.async {
                    self.loginSheetWinController?.window?.close()
                    self.settings.credentials!.deleteLogin()
                    var updatedSettings = self.settings
                    updatedSettings.credentials = nil
                    self.update(updatedSettings)
                    self.otpField.stringValue = ""
                }
            default:
                DispatchQueue.main.async {
                    self.loginSheetWinController?.window?.close()
                }
            }
        }
        queue.addOperation(op)
    }
    
    func startGame(sid: String, settings: FFXIVSettings) {
        let queue = OperationQueue()
        let op = StartGameOperation(settings: settings, sid: sid)
        queue.addOperation(op)
    }

}
