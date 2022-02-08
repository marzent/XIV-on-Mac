//
//  LaunchController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Cocoa

class LaunchController: NSViewController {
    
    var loginSheetWinController: NSWindowController?
    var settings: FFXIVSettings = FFXIVSettings()
    
    @IBOutlet private var loginButton: NSButton!
    @IBOutlet private var userField: NSTextField!
    @IBOutlet private var passwdField: NSTextField!
    @IBOutlet private var otpField: NSTextField!
    @IBOutlet private var scrollView: AnimatingScrollView!
    
    
    override func viewDidAppear() {
        super.viewDidAppear()
        update(FFXIVSettings.storedSettings())
        loginSheetWinController = storyboard?.instantiateController(withIdentifier: "LoginSheet") as? NSWindowController
        view.window?.isMovableByWindowBackground = true
        DispatchQueue.global(qos: .userInteractive).async {
            let frontier = Frontier.info!
            self.populateNews(frontier)
        }
    }
    
    private func populateNews(_ info: Frontier.Info) {
        DispatchQueue.main.async {
            self.scrollView.banners = info.banner
        }
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
    
    private let animationDuration = 3.0
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
        self.timer = Timer.scheduledTimer(withTimeInterval: 7, repeats: true, block: { _ in
            self.animate()
            })
    }
    
    // This will override and cancel any running scroll animations
    override public func scroll(_ clipView: NSClipView, to point: NSPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        contentView.setBoundsOrigin(point)
        CATransaction.commit()
        //super.scroll(clipView, to: point)
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
    
    public func animate() {
        if let banners = banners {
            index = (index + 1) % banners.count
            self.scroll(toPoint: NSPoint(x: Int(width) * index, y: 0), animationDuration: animationDuration)
        }
    }

}
