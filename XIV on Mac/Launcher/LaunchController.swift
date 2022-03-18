//
//  LaunchController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Cocoa

class LaunchController: NSViewController, NSWindowDelegate {
    
    var loginSheetWinController: NSWindowController?
    var installerWinController: NSWindowController?
    var patchWinController: NSWindowController?
    var newsTable: FrontierTableView!
    var topicsTable: FrontierTableView!
    var otp: OTP? = nil
    
    @IBOutlet private var loginButton: NSButton!
    @IBOutlet weak var userField: NSTextField!
    @IBOutlet private var passwdField: NSTextField!
    @IBOutlet weak var otpField: NSTextField!
    @IBOutlet weak var otpCheck: NSButton!
    @IBOutlet private var scrollView: AnimatingScrollView!
    @IBOutlet private var newsView: NSScrollView!
    @IBOutlet private var topicsView: NSScrollView!
    
    override func loadView() {
        super.loadView()
        update()
        setupOTP()
        ACT.observe()
        NotificationCenter.default.addObserver(self,selector: #selector(installDone(_:)),name: .installDone, object: nil)
        if #available(macOS 11.0, *) {
            newsTable = FrontierTableView(icon: NSImage(systemSymbolName: "newspaper", accessibilityDescription: nil)!)
            topicsTable = FrontierTableView(icon: NSImage(systemSymbolName: "newspaper.fill", accessibilityDescription: nil)!)
        }
        else {
            newsTable = FrontierTableView(icon: NSImage(size: NSSize(width: 20, height: 20)))
            topicsTable = FrontierTableView(icon: NSImage(size: NSSize(width: 20, height: 20)))
        }
        newsView.documentView = newsTable.tableView
        topicsView.documentView = topicsTable.tableView
        DispatchQueue.global(qos: .userInitiated).async {
            self.checkBoot()
        }
        DispatchQueue.global(qos: .userInteractive).async {
            if let frontier = Frontier.info {
                self.populateNews(frontier)
            }
        }
    }
    
    @objc func installDone(_ notif: Notification) {
        checkBoot()
    }
    
    func checkBoot() {
        if let bootPatches = try? FFXIVLogin.bootPatches, !bootPatches.isEmpty {
            startPatch(bootPatches)
        }
        DispatchQueue.main.async {
            self.loginButton.isEnabled = true
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        loginSheetWinController = storyboard?.instantiateController(withIdentifier: "LoginSheet") as? NSWindowController
        installerWinController = storyboard?.instantiateController(withIdentifier: "InstallerWindow") as? NSWindowController
        patchWinController = storyboard?.instantiateController(withIdentifier: "PatchSheet") as? NSWindowController
        view.window?.delegate = self
        view.window?.isMovableByWindowBackground = true
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.hide(nil)
        return false
    }
    
    private func populateNews(_ info: Frontier.Info) {
        DispatchQueue.main.async {
            self.topicsTable.add(items: info.topics)
            self.newsTable.add(items: info.pinned + info.news)
            self.scrollView.banners = info.banner
        }
    }
    
    private func update() {
        userField.stringValue = FFXIVSettings.credentials?.username ?? ""
        passwdField.stringValue = FFXIVSettings.credentials?.password ?? ""
    }
    
    @IBAction func doLogin(_ sender: Any) {
        doLogin()
    }
    
    func doLogin() {
        view.window?.beginSheet(loginSheetWinController!.window!)
        FFXIVSettings.credentials = FFXIVLoginCredentials(username: userField.stringValue, password: passwdField.stringValue, oneTimePassword: otpField.stringValue)
        do {
            let (uid, patches) = try FFXIVLogin().result
            guard patches.isEmpty else {
                loginSheetWinController?.window?.close()
                DispatchQueue.global(qos: .userInteractive).async {
                    self.startPatch(patches)
                }
                return
            }
            FFXIVApp().start(sid: uid)
            return
        } catch FFXIVLoginError.noInstall {
            loginSheetWinController?.window?.close()
            view.window?.beginSheet(self.installerWinController!.window!)
        } catch {
            loginSheetWinController?.window?.close()
            let error = error as! LocalizedError
            let alert = NSAlert()
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.messageText = error.failureReason ?? "Error"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }
    
    func startPatch(_ patches: [Patch]) {
        DispatchQueue.main.async {
            self.view.window?.beginSheet(self.patchWinController!.window!)
            let patchController = self.patchWinController!.contentViewController! as! PatchController
            patchController.install(patches)
        }
    }

}

final class BannerView: NSImageView {
    
    var banner: Frontier.Info.Banner? {
        didSet {
            self.image = NSImage(contentsOf: URL(string: banner!.lsbBanner)!)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if let banner = banner {
            let url = URL(string: banner.link)!
            NSWorkspace.shared.open(url)
        }
    }

}

final class AnimatingScrollView: NSScrollView {
    
    private var width: CGFloat  {
        return self.contentSize.width
    }
    
    private var height: CGFloat  {
        return self.contentSize.height
    }
    
    private let animationDuration = 2.0
    private let stayDuration = 8.0
    private var index = 0
    private var timer = Timer()
    
    var banners: [Frontier.Info.Banner]? {
        didSet {
            let banners = banners!
            self.documentView?.setFrameSize(NSSize(width: width * CGFloat(banners.count), height: height))
            for (i, banner) in banners.enumerated() {
                let bannerView = BannerView()
                bannerView.frame = CGRect(x: CGFloat(i) * width, y: 0, width: width, height: height)
                bannerView.imageScaling = .scaleNone
                bannerView.banner = banner
                self.documentView?.addSubview(bannerView)
            }
            self.startTimer()
        }
    }
    
    
    private func startTimer() {
        self.timer.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: stayDuration, repeats: true, block: { _ in
            self.animate()
            })
    }
    
    // This will override and cancel any running scroll animations
    override public func scroll(_ clipView: NSClipView, to point: NSPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        contentView.setBoundsOrigin(point)
        CATransaction.commit()
        super.scroll(clipView, to: point)
        index = Int(floor((point.x + width / 2) / width))
        let snap_x = CGFloat(index) * width
        scroll(toPoint: NSPoint(x: snap_x, y: 0), animationDuration: animationDuration)
        self.startTimer()
    }

    private func scroll(toPoint: NSPoint, animationDuration: Double) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = animationDuration
        contentView.animator().setBoundsOrigin(toPoint)
        reflectScrolledClipView(contentView)
        NSAnimationContext.endGrouping()
    }
    
    private func animate() {
        if let banners = banners {
            index = (index + 1) % banners.count
            self.scroll(toPoint: NSPoint(x: Int(width) * index, y: 0), animationDuration: animationDuration)
        }
    }

}
