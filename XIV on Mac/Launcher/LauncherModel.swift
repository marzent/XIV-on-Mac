//
//  LauncherModel.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 29.09.26.
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class LauncherModel: ObservableObject {
    enum Phase { case preparing, ready, login, patching, repairing, playing }
    enum Sheet: String, Identifiable {
        case installer, otp, rosetta
        var id: String { rawValue }
    }

    @Published var username = "" {
        didSet {
            if username != oldValue { oneTimePassword = "" }
        }
    }
    @Published var password = ""
    @Published var oneTimePassword = "" {
        didSet {
            let digits = OneTimeCode.sanitize(oneTimePassword)
            if oneTimePassword != digits { oneTimePassword = digits }
        }
    }
    @Published var autoLogin = Settings.autoLogin {
        didSet { Settings.autoLogin = autoLogin }
    }
    @Published var automaticOTP = Settings.usesOneTimePassword
    @Published var accounts: [LoginCredentials] = []
    @Published var phase: Phase = .preparing
    @Published var status = String(localized: "Preparing launcher…")
    @Published var news: [Frontier.Info.News] = []
    @Published var topics: [Frontier.Info.News] = []
    @Published var banners: [Frontier.LoadedBanner] = []
    @Published var loadingBanners = true
    @Published var loadingNews = true
    @Published var newsUnavailable = false
    @Published var notice: AppNotice?
    @Published var sheet: Sheet?
    @Published var selectingGamePath = false
    @Published var unvalidatedGamePath: URL?
    @Published var needsFirstAid = false
    @Published private(set) var runningGames = 0
    let patcher = PatchController()
    let repairer = RepairController()
    private var otp: OTP?
    private var otpUsername: String?
    private var observers = Set<AnyCancellable>()
    private var started = false
    private var migrated = false
    private var refreshingNews = false
    private var launcherUpdatePending = true
    private var pendingAutoLogin = false
    private var autoLoginSuppressed = false
    private let bannerImages = MemoryPrefetchCache<NSImage> { url in
        try? await backgroundWork { Frontier.fetchImage(url: url) }
    }

    var isBusy: Bool { phase != .ready && phase != .playing }
    var canLogin: Bool {
        (phase == .ready || phase == .playing)
            && !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
            && OneTimeCode.isValid(oneTimePassword)
    }

    init() {
        NotificationCenter.default.publisher(for: .loginInfo)
            .receive(on: DispatchQueue.main).sink { [weak self] notification in
                if let info = notification.userInfo?[Notification.status.info]
                    as? String
                {
                    self?.status = info
                }
            }.store(in: &observers)
        NotificationCenter.default.publisher(for: .otpPush)
            .receive(on: DispatchQueue.main).sink { [weak self] notification in
                guard let self, let source = notification.object as? OTP,
                    source === self.otp, self.automaticOTP,
                    self.otpUsername == self.username
                else { return }
                if let info = notification.userInfo?[Notification.status.info]
                    as? String
                {
                    self.oneTimePassword = info
                }
            }.store(in: &observers)
    }

    func start(migrated: Bool) async {
        guard !started else { return }
        started = true
        self.migrated = migrated
        Task { await refreshNews() }
        status = String(localized: "Loading saved accounts…")
        let saved = try? await backgroundWork {
            (Settings.credentials, LoginCredentials.accounts)
        }
        username = saved?.0?.username ?? ""
        password = saved?.0?.password ?? ""
        accounts = saved?.1 ?? []
        configureOTP()
        if Util.getXOMRuntimeEnvironment() == .appleSiliconNative
            && !Util.rosettaIsInstalled()
        {
            sheet = .rosetta
        } else {
            await prepareRuntime()
        }
    }

    func installRosetta() {
        sheet = nil
        Task {
            status = String(localized: "Installing Rosetta…")
            _ = try? await backgroundWork {
                Util.launch(
                    exec: URL(fileURLWithPath: "/usr/sbin/softwareupdate"),
                    args: ["--install-rosetta", "--agree-to-license"],
                    blocking: true)
            }
            guard Util.rosettaIsInstalled() else {
                sheet = .rosetta
                return
            }
            await prepareRuntime()
        }
    }

    private func prepareRuntime() async {
        status = String(localized: "Preparing game runtime…")
        if !Util.supportedGPU() {
            notice = AppNotice("UNSUPPORTED_GPU", "UNSUPPORTED_GPU_INFORMATIVE")
        }
        let needsMigration = migrated
        _ = try? await backgroundWork {
            Wine.boot()
            if needsMigration { PrefixMigrator.migrateWineRegistrySettings() }
        }
        await checkBoot()
    }

    private func checkBoot(thenLogin: Bool = false) async {
        phase = .preparing
        status = String(localized: "Checking for updates…")
        do {
            let patches = try await backgroundWork { try Patch.bootPatches }
            if !patches.isEmpty && (FFXIVApp().installed || thenLogin) {
                phase = .patching
                try await patcher.install(patches)
            }
            phase = .ready
            status = String(localized: "Ready to play")
            let bypass = NSEvent.modifierFlags.contains(.shift)
            if thenLogin {
                login()
            } else {
                pendingAutoLogin = autoLogin && !bypass
                attemptAutoLogin()
            }
        } catch {
            restoreIdle()
            notice = AppNotice(
                "PATCH_ERROR_MESSAGE", error.localizedDescription)
        }
    }

    func launcherUpdateCheckStarted() {
        launcherUpdatePending = true
    }

    func launcherUpdateCheckFinished() {
        launcherUpdatePending = false
        attemptAutoLogin()
    }

    func suppressAutoLoginForSession() {
        autoLoginSuppressed = true
        pendingAutoLogin = false
    }

    private func attemptAutoLogin() {
        guard pendingAutoLogin, !launcherUpdatePending else { return }
        pendingAutoLogin = false
        guard autoLogin, !autoLoginSuppressed, phase == .ready,
            runningGames == 0, !NSEvent.modifierFlags.contains(.shift)
        else { return }
        login()
    }

    func refreshNews() async {
        guard !refreshingNews else { return }
        refreshingNews = true
        loadingNews = true
        loadingBanners = true
        defer {
            refreshingNews = false
            loadingNews = false
            loadingBanners = false
        }
        async let bannerResult = prefetchBanners()
        let info = try? await backgroundWork { Frontier.info }
        if let info {
            news = info.pinned + info.news
            topics = info.topics
        }
        newsUnavailable = info == nil
        loadingNews = false
        if let fetched = await bannerResult { banners = fetched }
    }

    private func prefetchBanners() async -> [Frontier.LoadedBanner]? {
        guard let metadata = try? await backgroundWork({ Frontier.banners })
        else {
            return nil
        }
        let urls = metadata.compactMap { URL(string: $0.lsbBanner) }
        let images = await bannerImages.prefetch(urls)
        let loaded = metadata.compactMap { banner -> Frontier.LoadedBanner? in
            guard let url = URL(string: banner.lsbBanner),
                let image = images[url],
                let destination = URL(string: banner.link)
            else { return nil }
            return Frontier.LoadedBanner(
                id: banner.lsbBanner, destination: destination, image: image)
        }
        return loaded.isEmpty && !metadata.isEmpty ? nil : loaded
    }

    func selectAccount(_ account: LoginCredentials) {
        username = account.username
        password = account.password
        oneTimePassword = ""
        configureOTP(force: true)
    }

    func configureOTP(force: Bool = false) {
        let account = automaticOTP && !username.isEmpty ? username : nil
        guard force || account != otpUsername else { return }
        otp?.stop()
        otp = nil
        otpUsername = account
        oneTimePassword = ""
        if let account { otp = OTP(username: account) }
    }

    func toggleAutomaticOTP(_ enabled: Bool) {
        automaticOTP = enabled
        Settings.usesOneTimePassword = enabled
        if enabled && !OTP.secretStored(username: username) { sheet = .otp }
        configureOTP()
    }

    func saveOTP(secret: String) {
        OTP.store(username: username, secret: secret)
        configureOTP(force: true)
        sheet = nil
    }

    func finishInstallation() {
        sheet = nil
        Task { await checkBoot(thenLogin: true) }
    }

    func chooseGamePath(_ url: URL) {
        if InstallerView.isValidGameDirectory(gamePath: url.path) {
            Settings.gamePath = url
        } else {
            unvalidatedGamePath = url
        }
    }

    func login(repair: Bool = false) {
        guard canLogin else { return }
        pendingAutoLogin = false
        if FirstAidModel().cfgCheckSevereProblems() {
            needsFirstAid = true
            return
        }
        Settings.credentials = LoginCredentials(
            username: username, password: password,
            oneTimePassword: oneTimePassword.isEmpty ? nil : oneTimePassword)
        phase = .login
        status = NSLocalizedString("LOGGING_IN", comment: "")
        Task {
            do {
                guard FFXIVApp().installed else {
                    throw FFXIVLoginError.noInstall
                }
                let result = try await backgroundWork {
                    GraphicsInstaller.ensureBackend()
                    if Frontier.loginMaintenance {
                        throw FFXIVLoginError.maintenance
                    }
                    return try LoginResult(repair)
                }
                guard result.state != .NoService else {
                    throw FFXIVLoginError.notPlayable
                }
                if result.state == .NoTerms {
                    Wine.launch(command: "\"\(FFXIVApp().bootExe64URL.path)\"")
                    throw FFXIVLoginError.noTerms
                }
                if repair {
                    phase = .repairing
                    let message = await repairer.repair(result)
                    restoreIdle()
                    notice = AppNotice("REPAIR_RESULT", message)
                    return
                }
                if let patches = result.pendingPatches, !patches.isEmpty {
                    phase = .patching
                    try await patcher.install(patches)
                }
                phase = .login
                status = String(localized: "Updating Dalamud")
                let dalamud = try await backgroundWork {
                    if Frontier.gameMaintenance {
                        throw FFXIVLoginError.maintenance
                    }
                    return result.dalamudInstallState
                }
                if Settings.dalamudEnabled && dalamud == .failed {
                    notice = AppNotice(
                        "DALAMUD_START_FAILURE",
                        "DALAMUD_START_FAILURE_INFORMATIONAL")
                }
                status = String(localized: "Starting Game")
                let process = try await backgroundWork {
                    try result.startGame(dalamud == .ok)
                }
                phase = .playing
                status = String(localized: "Game running")
                runningGames += 1
                NSApp.hide(nil)
                AddOn.launchNotify()
                Task { await monitor(process) }
                if let saved = try? await backgroundWork({
                    LoginCredentials.accounts
                }) {
                    accounts = saved
                }
            } catch FFXIVLoginError.noInstall {
                restoreIdle()
                sheet = .installer
            } catch {
                restoreIdle()
                oneTimePassword = ""
                let title: String
                switch error {
                case XLError.loginError: title = "LOGIN_ERROR"
                case XLError.startError: title = "START_ERROR"
                default:
                    title = (error as? LocalizedError)?.failureReason ?? "Error"
                }
                notice = AppNotice(title, error.localizedDescription)
            }
        }
    }

    private func monitor(_ process: ProcessInformation) async {
        let exitCode = (try? await backgroundWork { process.exitCode }) ?? -1
        Log.information("Game exited with exit code \(exitCode)")
        runningGames = max(0, runningGames - 1)
        if !isBusy {
            restoreIdle()
        }
        if exitCode != 0 && Settings.nonZeroExitError {
            NSApp.unhide(nil)
            notice = AppNotice(
                "GAME_START_FAILURE", "GAME_START_FAILURE_INFORMATIONAL")
        } else if Settings.exitWithGame && runningGames == 0 && !isBusy {
            Util.quit()
        }
    }

    private func restoreIdle() {
        phase = runningGames > 0 ? .playing : .ready
        status =
            runningGames > 0
            ? String(localized: "Game running")
            : String(localized: "Ready to play")
    }

}
