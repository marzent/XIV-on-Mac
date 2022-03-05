//
//  LoginSheetController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 03.02.22.
//

import Cocoa

class LoginSheetController: NSViewController {
    
    @IBOutlet private var status: NSTextField!
    @IBOutlet private var spinner: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupObservers()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        spinner.usesThreadedAnimation = true
        spinner.startAnimation(self)
    }
    
    @objc func loginUpdate(_ notif: Notification) {
        let info = notif.userInfo?[Notification.status.info]! as! String
        DispatchQueue.main.async {
            self.status.stringValue = info
        }
    }
    
    @objc func loginDone(_ notif: Notification) {
        DispatchQueue.main.async {
            self.status.stringValue = "Logging In"
            self.view.window?.close()
        }
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self,selector: #selector(loginUpdate(_:)),name: .loginInfo, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(loginDone(_:)),name: .gameStarted, object: nil)
    }
    
}
