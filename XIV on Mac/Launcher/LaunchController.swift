//
//  LaunchController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Cocoa
import WebKit
import XIVLauncher

class RecaptchaSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard urlSchemeTask.request.url?.absoluteString == "recaptcha://user.ffxiv.com.tw/recaptcha_page.html" else {
            urlSchemeTask.didFailWithError(NSError(domain: "RecaptchaSchemeHandler", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported URL"]))
            return
        }
        
        guard let htmlPath = Bundle.main.path(forResource: "recaptcha_page", ofType: "html"),
              let htmlContent = try? String(contentsOfFile: htmlPath, encoding: .utf8) else {
            urlSchemeTask.didFailWithError(NSError(domain: "RecaptchaSchemeHandler", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTML file not found"]))
            return
        }
        
        let response = HTTPURLResponse(
            url: urlSchemeTask.request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/html; charset=utf-8"]
        )!
        
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(htmlContent.data(using: .utf8)!)
        urlSchemeTask.didFinish()
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // No-op
    }
}

final class RecaptchaTokenProvider: NSObject, WKScriptMessageHandler {
    static let shared = RecaptchaTokenProvider()

    private var completion: ((Result<String, Error>) -> Void)?
    private var webView: WKWebView?

    func fetchToken(completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.async {
            self.cancel()
            self.completion = completion

            let contentController = WKUserContentController()
            contentController.add(self, name: "recaptchaToken")

            let config = WKWebViewConfiguration()
            config.userContentController = contentController
            config.setURLSchemeHandler(RecaptchaSchemeHandler(), forURLScheme: "recaptcha")

            let webView = WKWebView(frame: .zero, configuration: config)
            webView.isHidden = true
            self.webView = webView

            guard let url = URL(string: "recaptcha://user.ffxiv.com.tw/recaptcha_page.html") else {
                completion(.failure(NSError(
                    domain: "RecaptchaTokenProvider", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid recaptcha URL"])))
                self.cancel()
                return
            }

            webView.load(URLRequest(url: url))
        }
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "recaptchaToken" else { return }

        let token = message.body as? String ?? ""
        completion?(.success(token))
        cancel()
    }

    private func cancel() {
        webView?.stopLoading()
        webView = nil
        completion = nil
    }
}

class LaunchController: NSViewController, WKNavigationDelegate {
    var loginSheetWinController: NSWindowController?
    var installerWinController: NSWindowController?
    var patchWinController: NSWindowController?
    var repairWinController: NSWindowController?
    var patchController: PatchController?
    var repairController: RepairController?
    var newsTable: FrontierTableView!
    var newsWebView: WKWebView!  // 新增：WebView 覆蓋層
    var topicsTable: FrontierTableView!
    var otp: OTP?

    @IBOutlet private var loginButton: NSButton!
    @IBOutlet var userField: NSTextField!
    @IBOutlet private var userMenu: NSMenu!
    @IBOutlet private var passwdField: NSTextField!
    @IBOutlet var otpField: NSTextField!
    @IBOutlet var otpCheck: NSButton!
    @IBOutlet var autoLoginCheck: NSButton!
    @IBOutlet private var scrollView: AnimatingScrollView!
    @IBOutlet private var newsView: NSScrollView!
    @IBOutlet private var topicsView: NSScrollView!
    @IBOutlet private var newsContainerView: NSView!
    @IBOutlet var discloseButton: NSButton!
    @IBOutlet private var touchBarLoginButton: NSButtonTouchBarItem!
    @IBOutlet var leftButton: NSButton!
    @IBOutlet var rightButton: NSButton!

    override func loadView() {
        super.loadView()
        update()
        NotificationCenter.default.addObserver(
            self, selector: #selector(installDone(_:)), name: .installDone,
            object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(showSideButtons(_:)), name: .bannerEnter,
            object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(hideSideButtons(_:)), name: .bannerLeft,
            object: nil)
        userMenu.minimumWidth = 264
        newsTable = FrontierTableView(
            icon: NSImage(
                systemSymbolName: "newspaper", accessibilityDescription: nil)!)
        topicsTable = FrontierTableView(
            icon: NSImage(
                systemSymbolName: "newspaper.fill",
                accessibilityDescription: nil)!)
        newsView.documentView = newsTable.tableView
        topicsView.documentView = topicsTable.tableView
        leftButton.wantsLayer = true
        rightButton.wantsLayer = true
        setSideButtonVisibility(to: false)
        newsContainerView.isHidden = true
        newsContainerView.removeFromSuperview()

        // 移動 scrollView 向下填補新聞區域空間 (新聞區域高度124px)
        if let scrollView = self.scrollView {
            var frame = scrollView.frame
            frame.origin.y -= 124  // 向下移動124px
            frame.size.height += 124  // 增加高度124px
            scrollView.frame = frame
            // 禁用自動調整大小，完全手動控制位置
            scrollView.translatesAutoresizingMaskIntoConstraints = true
            scrollView.autoresizingMask = []
        }

        // 新增：建立 WebView 覆蓋層
        let webViewConfiguration = WKWebViewConfiguration()
        newsWebView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        newsWebView.translatesAutoresizingMaskIntoConstraints = false
        newsWebView.navigationDelegate = self
        // 設置圓角
        newsWebView.layer?.cornerRadius = 8.0
        newsWebView.layer?.masksToBounds = true

        // 將 WebView 添加到與 scrollView 相同的父視圖
        if let parentView = scrollView.superview {
            parentView.addSubview(newsWebView)

            // 設定約束，使 WebView 覆蓋整個 scrollView
            NSLayoutConstraint.activate([
                newsWebView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                newsWebView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                newsWebView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                newsWebView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            ])

            // 載入指定的網頁
            if let url = URL(string: "https://user-cdn.ffxiv.com.tw/news/251115/launcher_left.html") {
                let request = URLRequest(url: url)
                newsWebView.load(request)
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.checkBoot()
        }
        DispatchQueue.global(qos: .userInteractive).async {
            // TEMPORARILY DISABLED: News and banners loading
            // To re-enable: Uncomment the block below
            /*
            if let frontierInfo = Frontier.info {
                self.populateNews(frontierInfo)
            }
            if let frontierBanners = Frontier.banners {
                self.populateBanners(frontierBanners)
            }
            */
        }
    }

    @objc func installDone(_ notif: Notification) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.checkBoot(skipInstallCheck: true)
            DispatchQueue.main.async {
                self.doLogin()
            }
        }
    }

    @objc func hideSideButtons(_ notif: Notification) {
        setSideButtonVisibility(to: false)
    }

    @objc func showSideButtons(_ notif: Notification) {
        setSideButtonVisibility(to: true)
    }

    func setSideButtonVisibility(to: Bool) {
        let buttonAlpha = 0.4
        leftButton.layer?.backgroundColor = .black.copy(
            alpha: to ? buttonAlpha : 0.0)
        rightButton.layer?.backgroundColor = .black.copy(
            alpha: to ? buttonAlpha : 0.0)
    }

    func checkBoot(skipInstallCheck: Bool = false) {
        // TEMPORARILY DISABLED: Boot patches check
        // To re-enable: Uncomment the block below
        /*
        if let bootPatches = try? Patch.bootPatches, !bootPatches.isEmpty,
            FFXIVApp().installed || skipInstallCheck
        {
            startPatch(bootPatches)
        }
        */
        DispatchQueue.main.async {
            self.loginButton.isEnabled = true
            self.touchBarLoginButton.isEnabled = true
            if settings.autoLogin
                && NSEvent.modifierFlags.intersection(
                    .deviceIndependentFlagsMask) != .shift
            {
                self.doLogin()
            }
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        loginSheetWinController =
            storyboard?.instantiateController(withIdentifier: "LoginSheet")
            as? NSWindowController
        installerWinController =
            storyboard?.instantiateController(withIdentifier: "InstallerWindow")
            as? NSWindowController
        patchWinController =
            storyboard?.instantiateController(withIdentifier: "PatchSheet")
            as? NSWindowController
        repairWinController =
            storyboard?.instantiateController(withIdentifier: "RepairSheet")
            as? NSWindowController
        patchController =
            patchWinController!.contentViewController! as? PatchController
        repairController =
            repairWinController!.contentViewController! as? RepairController
    }

    private func populateNews(_ info: Frontier.Info) {
        DispatchQueue.main.async {
            self.topicsTable.add(items: info.topics)
            self.newsTable.add(items: info.pinned + info.news)
        }
    }

    private func populateBanners(_ banners: [Frontier.BannerRoot.Banner]) {
        DispatchQueue.main.async {
            self.scrollView.banners = banners
        }
    }

    private func update() {
        autoLoginCheck.state = Settings.autoLogin ? .on : .off
        userField.stringValue = Settings.credentials?.username ?? ""
        passwdField.stringValue = Settings.credentials?.password ?? ""
        setupOTP()
    }

    @objc func update(_ sender: userMenuItem) {
        userField.stringValue = sender.credentials.username
        passwdField.stringValue = sender.credentials.password
        setupOTP()
    }

    @IBAction func showAccounts(_ sender: Any) {
        userMenu.items = []
        let accounts = LoginCredentials.accounts
        for account in accounts {
            let item = userMenuItem(
                title: account.username, action: #selector(update(_:)),
                keyEquivalent: "")
            item.credentials = account
            userMenu.items += [item]
        }
        userMenu.popUp(
            positioning: userMenu.item(at: 0), at: NSPoint(x: 0, y: 29),
            in: userField)
    }

    @IBAction func autoLoginStateChange(_ sender: NSButton) {
        Settings.autoLogin = sender.state == .on

        if Settings.autoLogin {
            let alert: NSAlert = .init()
            alert.messageText = NSLocalizedString(
                "AUTOLOGIN_MESSAGE", comment: "")
            alert.informativeText = NSLocalizedString(
                "AUTOLOGIN_INFORMATIVE", comment: "")
            alert.alertStyle = .informational
            alert.addButton(
                withTitle: NSLocalizedString("BUTTON_OK", comment: ""))

            alert.runModal()
        }
    }

    @IBAction func doLogin(_ sender: Any) {
        doLogin()
    }

    @IBAction func doRepair(_ sender: Any) {
        doLogin(repair: true)
    }

    @IBAction func scrollLeft(_ sender: NSButton) {
        scrollView.scrollLeft()
    }

    @IBAction func scrollRight(_ sender: NSButton) {
        scrollView.scrollRight()
    }

    func problemConfigurationCheck() -> Bool {
        if FirstAidModel().cfgCheckSevereProblems() {
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.openFirstAid(self)
            return true
        }
        return false
    }

    func doLogin(repair: Bool = false) {
        // Check for show stopping problems
        if problemConfigurationCheck() {
            return
        }
        view.window?.beginSheet(loginSheetWinController!.window!)
        Settings.credentials = LoginCredentials(
            username: userField.stringValue, password: passwdField.stringValue,
            oneTimePassword: otpField.stringValue)
        RecaptchaTokenProvider.shared.fetchToken { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(token):
                // 印出取得的 reCaptcha token
                Log.information("Recaptcha token obtained: \(token)")
                print("Recaptcha token obtained: \(token)")
                
                // 繼續執行登入流程
                self.executeLogin(repair: repair, recaptchaToken: token)
            case let .failure(error):
                DispatchQueue.main.async {
                    self.loginSheetWinController?.window?.close()
                    let alert = NSAlert()
                    alert.addButton(
                        withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                    alert.alertStyle = .critical
                    alert.messageText = NSLocalizedString(
                        "LOGIN_RECAPTCHA_FAILED", comment: "")
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                }
            }
        }
    }

    private func executeLogin(repair: Bool, recaptchaToken: String) {
        DispatchQueue.global(qos: .default).async {
            do {
                guard FFXIVApp().installed else {
                    throw FFXIVLoginError.noInstall
                }
                DispatchQueue.global(qos: .userInitiated).async {
                    DiscordBridge.setPresence()
                    GraphicsInstaller.ensureBackend()
                }
                // TC Region: maintenance checks disabled
                // if Frontier.loginMaintenance {
                //     throw FFXIVLoginError.maintenance
                // }
                let loginResult = try LoginResult(repair, recaptchaToken: recaptchaToken)
                guard loginResult.state != .NoService else {
                    throw FFXIVLoginError.notPlayable
                }
                guard loginResult.state != .NoTerms else {
                    Wine.launch(command: "\"\(FFXIVApp().bootExe64URL.path)\"")
                    throw FFXIVLoginError.noTerms
                }
                if repair {
                    DispatchQueue.main.async { [self] in
                        loginSheetWinController?.window?.close()
                        view.window?.beginSheet(repairWinController!.window!)
                        repairController?.repair(loginResult)
                    }
                    return
                }
                if !(loginResult.pendingPatches?.isEmpty ?? true) {
                    DispatchQueue.main.async { [self] in
                        loginSheetWinController?.window?.close()
                    }
                    self.startPatch(loginResult.pendingPatches!)
                    DispatchQueue.main.async { [self] in
                        view.window?.beginSheet(
                            loginSheetWinController!.window!)
                    }
                }
                // TC Region: maintenance checks disabled
                // if Frontier.gameMaintenance {
                //     throw FFXIVLoginError.maintenance
                // }
                // NotificationCenter.default.post(
                //     name: .loginInfo, object: nil,
                //     userInfo: [Notification.status.info: "Updating Dalamud"])
                // TC Temporarily set dalamudInstallState to .ok
                let dalamudInstallState: Dalamud.InstallState = .failed
                DispatchQueue.main.async {
                    if Settings.dalamudEnabled && dalamudInstallState == .failed
                    {
                        let alert = NSAlert()
                        alert.addButton(
                            withTitle: NSLocalizedString(
                                "BUTTON_OK", comment: ""))
                        alert.alertStyle = .critical
                        alert.messageText = NSLocalizedString(
                            "DALAMUD_START_FAILURE", comment: "")
                        alert.informativeText = NSLocalizedString(
                            "DALAMUD_START_FAILURE_INFORMATIONAL", comment: "")
                        alert.runModal()
                    }
                }
                NotificationCenter.default.post(
                    name: .loginInfo, object: nil,
                    userInfo: [Notification.status.info: "Starting Game"])
                let process = try loginResult.startGame(
                    dalamudInstallState == .ok)
                DispatchQueue.main.async { [self] in
                    loginSheetWinController?.window?.close()
                    view.window?.close()
                }
                AddOn.launchNotify()
                let exitCode = process.exitCode
                Log.information("Game exited with exit code \(exitCode)")
                DispatchQueue.main.async {
                    // Exit codes 0 and 1 are considered normal (1 = user quit from title screen)
                    if exitCode != 0 && exitCode != 1 && Settings.nonZeroExitError {
                        let alert = NSAlert()
                        alert.addButton(
                            withTitle: NSLocalizedString(
                                "BUTTON_OK", comment: ""))
                        alert.alertStyle = .critical
                        alert.messageText = NSLocalizedString(
                            "GAME_START_FAILURE", comment: "")
                        alert.informativeText = NSLocalizedString(
                            "GAME_START_FAILURE_INFORMATIONAL", comment: "")
                        alert.runModal()
                    } else if Settings.exitWithGame {
                        Util.quit()
                    }
                }
            } catch FFXIVLoginError.noInstall {
                DispatchQueue.main.async { [self] in
                    loginSheetWinController?.window?.close()
                    view.window?.beginSheet(
                        self.installerWinController!.window!)
                }
            } catch let XLError.loginError(errorMessage) {
                DispatchQueue.main.async { [self] in
                    loginSheetWinController?.window?.close()
                    let alert = NSAlert()
                    alert.addButton(
                        withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                    alert.alertStyle = .critical
                    alert.messageText = NSLocalizedString(
                        "LOGIN_ERROR", comment: "")
                    alert.informativeText = errorMessage
                    alert.runModal()
                }
            } catch let XLError.startError(errorMessage) {
                DispatchQueue.main.async { [self] in
                    loginSheetWinController?.window?.close()
                    let alert = NSAlert()
                    alert.addButton(
                        withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                    alert.alertStyle = .critical
                    alert.messageText = NSLocalizedString(
                        "START_ERROR", comment: "")
                    alert.informativeText = errorMessage
                    alert.runModal()
                }
            } catch let error as FFXIVLoginError {
                DispatchQueue.main.async { [self] in
                    loginSheetWinController?.window?.close()
                    let alert = NSAlert()
                    alert.addButton(
                        withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                    alert.alertStyle = .critical
                    alert.messageText = error.failureReason ?? "Error"
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                }
            } catch {  // should not reach
                DispatchQueue.main.async { [self] in
                    loginSheetWinController?.window?.close()
                    let alert = NSAlert()
                    alert.addButton(
                        withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                    alert.alertStyle = .critical
                    alert.messageText = "Error"
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                }
            }
        }
    }

    func startPatch(_ patches: [Patch]) {
        if Thread.isMainThread {
            view.window?.beginSheet(patchWinController!.window!)
        } else {
            DispatchQueue.main.sync { [self] in
                view.window?.beginSheet(patchWinController!.window!)
            }
        }
        patchController?.install(patches)
    }

    @IBAction func tapTroubleshooting(_ sender: Any) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.openFirstAid(self)
    }

    @IBAction func tapBunnyHUD(_ sender: Any) {
        BunnyHUD.launch()
    }
}

class userMenuItem: NSMenuItem {
    var credentials: LoginCredentials!
}

final class BannerView: NSImageView {
    var banner: Frontier.BannerRoot.Banner? {
        didSet {
            let bannerURL = URL(string: banner!.lsbBanner)!
            DispatchQueue.global(qos: .background).async { [self] in
                let bannerImage = Frontier.fetchImage(
                    url: bannerURL)
                DispatchQueue.main.async { [self] in
                    image = bannerImage
                }
            }
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
    private var width: CGFloat {
        return contentSize.width
    }

    private var height: CGFloat {
        return contentSize.height
    }

    private let animationDuration = 2.0
    private let stayDuration = 8.0
    private var index = 0
    private var timer = Timer()

    var banners: [Frontier.BannerRoot.Banner]? {
        didSet {
            let banners = banners!
            documentView?.setFrameSize(
                NSSize(width: width * CGFloat(banners.count), height: height))
            for (i, banner) in banners.enumerated() {
                let bannerView = BannerView()
                bannerView.frame = CGRect(
                    x: CGFloat(i) * width, y: 0, width: width, height: height)
                bannerView.imageScaling = .scaleProportionallyUpOrDown
                bannerView.banner = banner
                documentView?.addSubview(bannerView)
            }
            startTimer()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        DispatchQueue.main.async { [self] in
            let trackingArea = NSTrackingArea(
                rect: bounds,
                options: [.activeInKeyWindow, .mouseEnteredAndExited],
                owner: self,
                userInfo: nil)
            addTrackingArea(trackingArea)
        }
    }

    func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(
            withTimeInterval: stayDuration, repeats: true,
            block: { _ in
                DispatchQueue.main.async {
                    self.animate()
                }
            })
    }

    func stopTimer() {
        timer.invalidate()
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
        scroll(
            toPoint: NSPoint(x: snap_x, y: 0),
            animationDuration: animationDuration)
        startTimer()
    }

    private func scroll(toPoint: NSPoint, animationDuration: Double) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = animationDuration
        contentView.animator().setBoundsOrigin(toPoint)
        reflectScrolledClipView(contentView)
        NSAnimationContext.endGrouping()
    }

    private func animate() {
        guard let banners = banners else { return }
        index = (index + 1) % banners.count
        scroll(
            toPoint: NSPoint(x: Int(width) * index, y: 0),
            animationDuration: animationDuration)
    }

    func scrollRight() {
        guard let banners = banners, index < banners.count - 1 else {
            return
        }
        startTimer()
        index += 1
        scroll(
            toPoint: NSPoint(x: Int(width) * index, y: 0),
            animationDuration: animationDuration)
    }

    func scrollLeft() {
        guard banners != nil, index > 0 else {
            return
        }
        startTimer()
        index -= 1
        scroll(
            toPoint: NSPoint(x: Int(width) * index, y: 0),
            animationDuration: animationDuration)
    }

    override func mouseEntered(with theEvent: NSEvent) {
        super.mouseEntered(with: theEvent)
        NotificationCenter.default.post(name: .bannerEnter, object: nil)
    }

    override func mouseExited(with theEvent: NSEvent) {
        super.mouseExited(with: theEvent)
        NotificationCenter.default.post(name: .bannerLeft, object: nil)
    }
}

// MARK: - WKNavigationDelegate
extension LaunchController {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // WebView 載入完成後，調整 scrollView 高度以適應內容
        webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] (result, error) in
            guard let self = self, let height = result as? CGFloat, error == nil else { return }
            
            DispatchQueue.main.async {
                self.adjustScrollViewHeight(for: height)
            }
        }
    }
    
    private func adjustWindowHeight(for contentHeight: CGFloat) {
        guard let window = view.window else { return }
        
        // 計算新的視窗高度
        // 考慮到其他 UI 元素的高度（如標題欄、按鈕等）
        let currentFrame = window.frame
        let titleBarHeight: CGFloat = 28  // 標題欄高度估計
        let buttonAreaHeight: CGFloat = 80  // 按鈕區域高度估計
        let minHeight: CGFloat = 400  // 最小視窗高度
        let maxHeight: CGFloat = 800  // 最大視窗高度
        
        // 新的視窗高度 = 內容高度 + 標題欄 + 按鈕區域
        var newHeight = contentHeight + titleBarHeight + buttonAreaHeight
        newHeight = max(minHeight, min(newHeight, maxHeight))  // 限制在合理範圍內
        
        // 調整視窗框架，保持視窗頂部位置不變
        let newFrame = NSRect(
            x: currentFrame.origin.x,
            y: currentFrame.origin.y + currentFrame.height - newHeight,
            width: currentFrame.width,
            height: newHeight
        )
        
        window.setFrame(newFrame, display: true, animate: true)
    }
    
    private func adjustScrollViewHeight(for contentHeight: CGFloat) {
        guard let scrollView = self.scrollView, let window = view.window else { return }

        // 設定高度上限為640px
        let maxHeight: CGFloat = 640
        let newHeight = min(contentHeight, maxHeight)

        // 獲取當前scrollView frame
        let currentScrollViewFrame = scrollView.frame

        // 計算高度變化量
        let heightDifference = newHeight - currentScrollViewFrame.height

        // 如果高度沒有變化，不需要調整
        guard heightDifference != 0 else { return }

        // 創建新的scrollView frame，保持頂部位置不變，只改變高度
        let newScrollViewFrame = NSRect(
            x: currentScrollViewFrame.origin.x,
            y: currentScrollViewFrame.origin.y,  // 保持頂部Y座標不變
            width: currentScrollViewFrame.width,
            height: newHeight
        )

        // 調整視窗高度
        let currentWindowFrame = window.frame
        let newWindowHeight = currentWindowFrame.height + heightDifference

        // 計算新的視窗frame，保持在畫面中央（水平和垂直）
        let screenFrame = NSScreen.main?.visibleFrame ?? NSScreen.main!.frame
        let newWindowFrame = NSRect(
            x: screenFrame.midX - currentWindowFrame.width / 2,  // 水平居中
            y: screenFrame.midY - newWindowHeight / 2,  // 垂直居中
            width: currentWindowFrame.width,
            height: newWindowHeight
        )

        // 同時調整scrollView和視窗
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            scrollView.frame = newScrollViewFrame
            window.setFrame(newWindowFrame, display: true)
        }
    }
}
