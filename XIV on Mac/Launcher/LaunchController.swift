//
//  LaunchController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Cocoa


class LaunchController: ObservableObject {
    @Published var installerController : InstallerController = InstallerController()
    @Published var patchController : PatchController = PatchController()
    @Published var repairController : RepairController = RepairController()
    @Published var firstAidController: FirstAidController = FirstAidController()
    var newsTable: FrontierTableView!
    var topicsTable: FrontierTableView!
    var otp: OTP?
    // These are the ones seen in the UI currently, not neccesarily the saved values
    @Published var currentUsername : String = Settings.credentials?.username ?? ""
    @Published var currentPassword : String = Settings.credentials?.password ?? ""
    @Published var currentOTPValue : String = Settings.credentials?.oneTimePassword ?? ""
    @Published var loginAllowed : Bool = false
    @Published var loggingIn : Bool = false // Is a login currently happening
    var displayingSheet : Bool {
        get {
            return loggingIn || repairController.repairing || installerController.installing || patchController.patching
        }
        set {
           if !newValue
            {
               self.loggingIn = false
           }
        }
    }

    @Published var loginStatusString : String = ""
    
    @Published var news : [Frontier.Info.News] = []
    @Published var topics : [Frontier.Info.News] = []
    @Published var banners : [Frontier.Info.Banner] = []
    
    @objc func installDone(_ notif: Notification) {
        checkBoot()
    }
    
    @objc func loginUpdate(_ notif: Notification) {
        let info = notif.userInfo?[Notification.status.info]! as! String
        DispatchQueue.main.async {
            self.loginStatusString = info
        }
    }
    
    required init()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(loginUpdate(_:)), name: .loginInfo, object: nil)
    }

    
    func checkBoot() {
        if let bootPatches = try? Patch.bootPatches, !bootPatches.isEmpty, FFXIVApp().installed {
            startPatch(bootPatches)
        }
        DispatchQueue.main.async {
            self.loginAllowed = true
            if settings.autoLogin && NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask) != .shift {
                self.doLogin()
            }
        }
    }
    
    public func populateNews(_ info: Frontier.Info) {
        // Fetch the banner images here so we don't cause main thread hangs doing so on-demand later.
        var loadedBanners : [Frontier.Info.Banner] = [Frontier.Info.Banner]()
        for var oneBanner in info.banner
        {
            oneBanner.bannerImage = Frontier.fetchImage(url: URL(string: oneBanner.lsbBanner)) ?? NSImage(systemSymbolName: "wifi.slash", accessibilityDescription: nil)!
            loadedBanners.append(oneBanner)
        }
        DispatchQueue.main.async {
            self.topics = info.topics
            self.news = info.pinned + info.news
            self.banners = loadedBanners
        }
    }
   
    func doRepair() {
        doLogin(repair: true)
    }
    
    func problemConfigurationCheck() -> Bool {
        if firstAidController.cfgCheckSevereProblems() {
            FirstAidWindowContent().openNewWindow(title: NSLocalizedString("FIRSTAID_WINDOW_TITLE", comment: ""), delegate: nil)
            return true
        }
        // If there were no major problems, see if we need to apply the Retina bug workaround.
        firstAidController.applyRetinaWorkaround()
        return false
    }
    
    func doLogin(repair: Bool = false) {
        // Check for show stopping problems
        if problemConfigurationCheck() {
            return
        }
        
        Settings.credentials = LoginCredentials(username: self.currentUsername, password: self.currentPassword, oneTimePassword: self.currentOTPValue)
        DispatchQueue.global(qos: .default).async {
            do {
                DispatchQueue.main.async { [self] in
                    self.loggingIn = true
                    self.loginAllowed = false
                    self.loginStatusString = NSLocalizedString("LOGIN_STATUS_LOGGING_IN", comment: "")
                }
                defer {
                    DispatchQueue.main.async { [self] in
                        self.loggingIn = false
                        self.loginAllowed = true
                    }
                }
                
                guard FFXIVApp().installed else {
                    throw FFXIVLoginError.noInstall
                }
                DispatchQueue.global(qos: .userInitiated).async {
                    DiscordBridge.setPresence()
                    Dxvk.install()
                }
                if Frontier.loginMaintenance {
                    throw FFXIVLoginError.maintenance
                }
                let loginResult = try LoginResult(repair)
                guard loginResult.state != .NoService else {
                    throw FFXIVLoginError.notPlayable
                }
                guard loginResult.state != .NoTerms else {
                    Wine.launch(command: "\"\(FFXIVApp().bootExe64URL.path)\"")
                    throw FFXIVLoginError.noTerms
                }
                if repair {
                    DispatchQueue.main.async { [self] in
                        repairController.repair(loginResult)
                    }
                    return
                }
                if !(loginResult.pendingPatches?.isEmpty ?? true) {
                    self.startPatch(loginResult.pendingPatches!)
                }
                if Frontier.gameMaintenance {
                    throw FFXIVLoginError.maintenance
                }
                NotificationCenter.default.post(name: .loginInfo, object: nil, userInfo: [Notification.status.info: NSLocalizedString("LOGIN_STATUS_DALAMUD_UPDATE", comment: "")])
                let dalamudInstallState = loginResult.dalamudInstallState
                DispatchQueue.main.async {
                    if Settings.dalamudEnabled && dalamudInstallState == .failed {
                        let alert = NSAlert()
                        alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                        alert.alertStyle = .critical
                        alert.messageText = NSLocalizedString("DALAMUD_START_FAILURE", comment: "")
                        alert.informativeText = NSLocalizedString("DALAMUD_START_FAILURE_INFORMATIONAL", comment: "")
                        alert.runModal()
                    }
                }
                NotificationCenter.default.post(name: .loginInfo, object: nil, userInfo: [Notification.status.info: NSLocalizedString("LOGIN_STATUS_GAME_START", comment: "")])
                DispatchQueue.main.async { [self] in
                    self.loggingIn = false
                }
                let process = try loginResult.startGame(dalamudInstallState == .ok)
                AddOn.launchNotify()
                let exitCode = process.exitCode
                Log.information("Game exited with exit code \(exitCode)")
                DispatchQueue.main.async {
                    if exitCode != 0 && Settings.nonZeroExitError {
                        let alert = NSAlert()
                        alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                        alert.alertStyle = .critical
                        alert.messageText = NSLocalizedString("GAME_START_FAILURE", comment: "")
                        alert.informativeText = NSLocalizedString("GAME_START_FAILURE_INFORMATIONAL", comment: "")
                        alert.runModal()
                    } else if Settings.exitWithGame {
                        Util.quit()
                    }
                }
            } catch FFXIVLoginError.noInstall {
                self.installerController.presentInstaller()
            } catch let XLError.loginError(errorMessage) {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                    alert.alertStyle = .critical
                    alert.messageText = NSLocalizedString("LOGIN_ERROR", comment: "")
                    alert.informativeText = errorMessage
                    alert.runModal()
                }
            } catch let XLError.startError(errorMessage) {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                    alert.alertStyle = .critical
                    alert.messageText = NSLocalizedString("START_ERROR", comment: "")
                    alert.informativeText = errorMessage
                    alert.runModal()
                }
            } catch let error as FFXIVLoginError {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                    alert.alertStyle = .critical
                    alert.messageText = error.failureReason ?? "Error"
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                }
            } catch { // should not reach
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                    alert.alertStyle = .critical
                    alert.messageText = "Error"
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                }
            }
        }
    }
    
    func startPatch(_ patches: [Patch]) {
        patchController.install(patches)
    }

}

