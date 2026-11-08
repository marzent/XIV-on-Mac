//
//  AppDelegate.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import AppMover
import Cocoa
import KeyboardShortcuts
import Sparkle
import SwiftUI
import UserNotifications
import XIVLauncher

@main
struct XIVOnMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Window("XIV on Mac", id: "launcher") {
            LauncherView(model: delegate.launcher)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .commands {
            LauncherCommands(
                model: delegate.launcher, updater: delegate.updater)
        }

        SwiftUI.Settings {
            SettingsView().tint(XOMStyle.accent)
        }
        .windowResizability(.contentMinSize)
        Window("FIRSTAID_WINDOW_TITLE", id: "first-aid") {
            FirstAidView().tint(XOMStyle.accent)
        }
        .defaultSize(width: 780, height: 780)
        Window("BENCHMARK_WINDOW_TITLE", id: "benchmark") {
            BenchmarkView().tint(XOMStyle.accent)
        }
        .defaultSize(width: 800, height: 680)
        Window("About XIV on Mac", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}

#if DEBUG
    #Preview("About") {
        AboutView()
    }
#endif

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate,
    @preconcurrency SPUUpdaterDelegate
{
    let launcher = LauncherModel()
    lazy var updater = SPUStandardUpdaterController(
        startingUpdater: false, updaterDelegate: self,
        userDriverDelegate: nil)
    private var screenCapture: ScreenCapture?

    func applicationWillFinishLaunching(_ notification: Notification) {
        guard !Util.isPreview else { return }
        var signalSet = sigset_t()
        sigemptyset(&signalSet)
        sigaddset(&signalSet, SIGUSR1)
        if pthread_sigmask(SIG_BLOCK, &signalSet, nil) != 0 {
            perror("pthread_sigmask")
        }
        Settings.syncToXL()
        let version =
            Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
        let build =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? ""
        initXL(
            "XIV on Mac \(version) build \(build)",
            Util.applicationSupport.path, Settings.verboseLogging,
            Frontier.frontierURLTemplate, Settings.dalamudBetaKind,
            Settings.dalamudBetaKey)
        Wine.setup()
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(wineAppWillActivate(_:)),
            name: Notification.Name("WineAppWillActivateNotification"),
            object: nil, suspensionBehavior: .deliverImmediately)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Util.isPreview else { return }
        let migrated = PrefixMigrator.migratePrefixIfNeeded()
        Util.make(dir: Util.cache)
        #if DEBUG
            Log.debug("Running in debug mode")
        #else
            AppMover.moveIfNecessary()
        #endif
        UNUserNotificationCenter.current().requestAuthorization(options: [
            .alert
        ]) { _, error in
            if let error { Log.warning(error.localizedDescription) }
        }
        screenCapture = ScreenCapture()
        KeyboardShortcuts.onKeyDown(for: .toggleVideoCapture) { [weak self] in
            self?.screenCapture?.toggleScreenCapture()
        }
        if Settings.skipAutoLoginAfterUpdate {
            Settings.skipAutoLoginAfterUpdate = false
            launcher.suppressAutoLoginForSession()
        }
        do {
            try updater.updater.start()
        } catch {
            Log.warning(error.localizedDescription)
            launcher.launcherUpdateCheckFinished()
        }
        // Start independently of SwiftUI window creation.
        Task { await launcher.start(migrated: migrated) }
    }

    func updater(
        _ updater: SPUUpdater, mayPerform updateCheck: SPUUpdateCheck
    ) throws {
        launcher.launcherUpdateCheckStarted()
    }

    func updater(
        _ updater: SPUUpdater,
        didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?
    ) {
        launcher.launcherUpdateCheckFinished()
    }

    func updater(
        _ updater: SPUUpdater, willScheduleUpdateCheckAfterDelay delay: TimeInterval
    ) {
        launcher.launcherUpdateCheckFinished()
    }

    func updaterWillNotScheduleUpdateCheck(_ updater: SPUUpdater) {
        launcher.launcherUpdateCheckFinished()
    }

    func updater(
        _ updater: SPUUpdater, userDidMake choice: SPUUserUpdateChoice,
        forUpdate update: SUAppcastItem, state: SPUUserUpdateState
    ) {
        if choice == .install { launcher.suppressAutoLoginForSession() }
    }

    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        launcher.suppressAutoLoginForSession()
        Settings.skipAutoLoginAfterUpdate = true
    }

    func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
        launcher.suppressAutoLoginForSession()
        Settings.skipAutoLoginAfterUpdate = true
    }

    @objc private func wineAppWillActivate(_ notification: Notification) {
        guard let pid = notification.userInfo?["ActivatingAppPID"] as? Int32,
            let app = NSRunningApplication(processIdentifier: pid)
        else { return }
        NSApp.yieldActivation(to: app)
        app.activate(from: NSRunningApplication.current, options: [])
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool
    { true }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool
    {
        Wine.launch(command: "\"\(filename)\"")
        return true
    }
}

struct LauncherCommands: Commands {
    @ObservedObject var model: LauncherModel
    let updater: SPUStandardUpdaterController
    @Environment(\.openWindow) private var openWindow
    @AppStorage("AutoLaunchBH") private var bunnyAutoLaunch = BunnyHUD
        .autoLaunch

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About XIV on Mac") { openWindow(id: "about") }
            Button("Check for Updates…") { updater.checkForUpdates(nil) }
        }
        CommandGroup(after: .newItem) {
            Button("Open…") { Wine.launch(command: "explorer") }
                .keyboardShortcut("o")
            Button("Open Install Folder") {
                NSWorkspace.shared.open(Util.applicationSupport)
            }
            .keyboardShortcut("i")
            Button("Select Game Path") {
                openWindow(id: "launcher")
                model.selectingGamePath = true
            }.keyboardShortcut("o", modifiers: [.command, .shift]).disabled(
                model.isBusy)
            Button("Repair Game Files") {
                openWindow(id: "launcher")
                model.login(repair: true)
            }.keyboardShortcut("r").disabled(!model.canLogin)
            Divider()
            Button("Run Benchmark") { openWindow(id: "benchmark") }
        }
        CommandMenu("Tools") {
            Button("Troubleshooting…") { openWindow(id: "first-aid") }
            Divider()
            Button("Edit Registry") { Wine.launch(command: "regedit") }
            Button("Wine Configuration") { Wine.launch(command: "winecfg") }
            Button("Command Line") { Wine.launch(command: "wineconsole") }
        }
        CommandMenu("Add On") {
            Button("Start Bunny HUD") { BunnyHUD.launch() }
            Toggle(
                "Auto-Launch Bunny HUD",
                isOn: Binding(
                    get: { bunnyAutoLaunch },
                    set: {
                        bunnyAutoLaunch = $0
                        BunnyHUD.autoLaunch = $0
                    }))
        }
        CommandGroup(replacing: .help) {
            Link(
                "XIV on Mac Help",
                destination: URL(
                    string: "https://www.xivmac.com/xiv-mac-application-help")!)
            Link(
                "Discord",
                destination: URL(string: "https://discord.gg/dWN5bTC4Yv")!)
            Link(
                "Compatibility",
                destination: URL(
                    string: "https://www.xivmac.com/compatibility-database")!)
        }
    }
}

struct AboutView: View {
    @State private var showingLicenses = false
    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable().frame(
                    width: 100, height: 100)
            Text("XIV on Mac").font(
                .system(size: 30, weight: .bold, design: .rounded))
            Text("Your next adventure starts here.").foregroundStyle(.secondary)
            Text(
                "Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")"
            )
            .font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 20) {
                Link(
                    "xivmac.com",
                    destination: URL(string: "https://www.xivmac.com")!)
                Button("Licenses") { showingLicenses = true }.buttonStyle(.link)
            }
        }
        .padding(44).frame(width: 420).modifier(AppWindowBackground())
        .sheet(isPresented: $showingLicenses) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Licenses & acknowledgements").font(.title2.bold())
                ScrollView {
                    Text(licenses).font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack {
                    Link(
                        "Source code",
                        destination: URL(
                            string: "https://github.com/XIV-on-Mac/XIV-on-Mac")!
                    )
                    Spacer()
                    Button("BUTTON_DONE") { showingLicenses = false }
                        .keyboardShortcut(.defaultAction)
                }
            }.padding(28).frame(width: 680, height: 560)
        }
    }

    private var licenses: String {
        guard
            let url = Bundle.main.url(
                forResource: "Credits", withExtension: "html"),
            let text = try? String(contentsOf: url, encoding: .utf8)
        else { return "" }
        return text
    }

}
