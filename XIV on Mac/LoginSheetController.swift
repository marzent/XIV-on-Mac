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
        status.stringValue = NSLocalizedString("LOGGING_IN", comment: "")
    }
    
    @objc func loginUpdate(_ notif: Notification) {
        let info = notif.userInfo?[Notification.status.info]! as! String
        DispatchQueue.main.async {
            self.status.stringValue = info
        }
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self,selector: #selector(loginUpdate(_:)),name: .loginInfo, object: nil)
    }
    
}
