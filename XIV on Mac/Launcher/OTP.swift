//
//  OTP.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 13.02.22.
//

import Base32
import Cocoa
import Embassy
import KeychainAccess

class OTP {
    private let loop: SelectorEventLoop
    private var server: DefaultHTTPServer?
    private static let keychain = Keychain(server: "https://secure.square-enix.com", protocolType: .https)
    private var generator: TOTP?
    private var timer = Timer()
    
    init(username: String) {
        loop = try! SelectorEventLoop(selector: try! KqueueSelector())
        server = DefaultHTTPServer(eventLoop: loop, interface: "::", port: 4646) {
            (
                environ: [String: Any],
                startResponse: (String, [(String, String)]) -> Void,
                sendBody: (Data) -> Void
            ) in
            // Start HTTP response
            startResponse("200 OK", [])
            let pathInfo = environ["PATH_INFO"]! as! String
            let components = pathInfo.split(separator: "/")
            if components.count == 2 && components[0] == "ffxivlauncher" && Int(components[1]) != nil {
                let otp = String(components[1])
                self.push(otp: otp)
                sendBody(Data("You successfully send the OTP \(otp)".utf8))
            }
            else {
                sendBody(Data("Please send in the format http://[Your PC Address]:4646/ffxivlauncher/[one-time password]".utf8))
            }
            // send EOF
            sendBody(Data())
        }
        generator = retrieve(username: username)
        start()
    }
    
    static func secretStored(username: String) -> Bool {
        return OTP.keychain[data: "\(username)(OTP secret)"] != nil
    }
    
    static func store(username: String, secret: String) {
        let cleanSecret = secret.components(separatedBy: .whitespaces).joined()
        keychain[data: "\(username)(OTP secret)"] = base32DecodeToData(cleanSecret)
    }
    
    private func retrieve(username: String) -> TOTP? {
        if let secret = OTP.keychain[data: "\(username)(OTP secret)"] {
            return TOTP(secret: secret)
        }
        else {
            return nil
        }
    }
    
    private func push(otp: String?) {
        NotificationCenter.default.post(name: .otpPush, object: nil, userInfo: [Notification.status.info: otp ?? ""])
    }
    
    private func startServer() {
        DispatchQueue.global(qos: .utility).async {
            self.loop.runForever()
        }
        try? server?.start()
    }
    
    private func stopServer() {
        loop.stop()
        server?.stop()
    }
    
    func start() {
        startServer()
        if generator != nil {
            push(otp: generator?.token)
            timer.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true, block: { _ in
                self.push(otp: self.generator?.token)
            })
        }
    }
    
    func stop() {
        stopServer()
        timer.invalidate()
    }
    
    static func getOTPSecretIfNeeded(username : String)
    {
        if !OTP.secretStored(username: username) {
            let msg = NSAlert()
            msg.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
            msg.addButton(withTitle: NSLocalizedString("BUTTON_CANCEL", comment: ""))
            msg.messageText = String(format: NSLocalizedString("OTP_MESSAGE", comment: ""), username)
            msg.informativeText = NSLocalizedString("OTP_INFORMATIVE", comment: "")
            let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            msg.accessoryView = txt
            if msg.runModal() == .alertFirstButtonReturn {
                OTP.store(username: username, secret: txt.stringValue)
            }
            txt.stringValue = ""
        }
    }

}

extension LaunchController {
    typealias settings = Settings
    
    func setupOTP() {
        NotificationCenter.default.addObserver(self, selector: #selector(otpUpdate(_:)), name: .otpPush, object: nil)
        if settings.usesOneTimePassword {
            enableOTP()
        }
    }
    
    @objc func otpUpdate(_ notif: Notification) {
        let info = notif.userInfo?[Notification.status.info]! as! String
        DispatchQueue.main.async {
            self.currentOTPValue = info
        }
    }
    
    func enableOTP() {
        otp = OTP(username: currentUsername)
    }
}
