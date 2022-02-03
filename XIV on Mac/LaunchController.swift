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
    
    var settings: FFXIVSettings = FFXIVSettings()
    
    override func viewDidAppear() {
        super.viewDidAppear()
        settings = FFXIVSettings.storedSettings()
        userField.stringValue = settings.credentials?.username ?? ""
        passwdField.stringValue = settings.credentials?.password ?? ""
        loginSheetWinController = storyboard?.instantiateController(withIdentifier: "LoginSheet") as? NSWindowController
        Dalamud.install()
        settings.dalamud = true
    }
    
    @IBAction func doLogin(_ sender: Any) {
        view.window?.beginSheet(loginSheetWinController!.window!)
        settings.credentials = FFXIVLoginCredentials(username: userField.stringValue, password: passwdField.stringValue)
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
            default:
                DispatchQueue.main.async {
                    self.loginSheetWinController?.window?.close()
                    self.settings.credentials!.deleteLogin()
                    var updatedSettings = self.settings
                    updatedSettings.credentials = nil
                    self.settings = updatedSettings
                }
            }
        }
        queue.addOperation(op)
    }
    
    func startGame(sid: String, settings: FFXIVSettings) {
        let queue = OperationQueue()
        let op = StartGameOperation(settings: settings, sid: sid)
        op.completionBlock = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                NotificationCenter.default.post(name: .loginDone, object: nil)
            }
        }
        queue.addOperation(op)
    }

}
