//
//  LaunchWindowContent.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/16/23.
//

import SwiftUI

struct LoginSheetContent: View {
    @EnvironmentObject var launchController: LaunchController

    var body: some View {
        VStack {
            ProgressView(launchController.loginStatusString).padding()
        }
        .frame(width: 200, height: 200)
    }
}

struct LoginSheetContent_Previews: PreviewProvider {
    static var previews: some View {
        LoginSheetContent()
            .environmentObject(LaunchController())
    }
}

struct LaunchWindowContent: View {
    @Environment(\.openURL) var openURL
    @EnvironmentObject var appDelegate: AppDelegate

    @State var carouselIndex = 0
    @State var autoLogin: Bool = Settings.autoLogin
    @State var autoOTP: Bool = Settings.usesOneTimePassword
    @State var showingTouchbarAddons: Bool = false

    @EnvironmentObject var launchController: LaunchController

    // Silly stuff for the wandering touchbar chocobo
    private let chocoWalkTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State var chocoWalkFrame: UInt = 0
    @State var chocoWalkOffset: CGFloat = 0
    @State var chocoFacing: Bool = false // false = left, true = right

    var body: some View {
        let showSheetBinding = Binding(
            get: { self.launchController.displayingSheet },
            set: {
                self.launchController.displayingSheet = $0
            }
        )

        VStack {
            HStack {
                CarouselView(index: $carouselIndex.animation(), maxIndex: launchController.banners.count) {
                    if launchController.banners.count > 0 {
                        ForEach($launchController.banners) { $oneBanner in
                            Image(nsImage: oneBanner.bannerImage)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    else {
                        ProgressView("LAUNCHER_LOADING")
                    }
                }
                .frame(width: 640.0, height: 250.0, alignment: .topLeading)
                .aspectRatio(contentMode: .fit)
                .onTapGesture {
                    if launchController.banners.count >= carouselIndex {
                        if let seURL = URL(string: launchController.banners[carouselIndex].link) {
                            openURL(seURL)
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.global(qos: .userInteractive).async {
                        if let frontier = Frontier.info {
                            launchController.populateNews(frontier)
                        }
                    }
                }

                VStack {
                    HStack {
                        Text("LAUNCHER_SE_ID")
                            .frame(alignment: .leading)
                        Spacer()
                    }
                    HStack {
                        TextField("LAUNCHER_SE_ID_PLACEHOLDER", text: $launchController.currentUsername)
                        Menu {
                            if LoginCredentials.accounts.count > 0 {
                                ForEach(LoginCredentials.accounts) { oneAccount in
                                    Button(oneAccount.username) {
                                        launchController.currentUsername = oneAccount.username
                                        launchController.currentPassword = oneAccount.password
                                    }
                                }
                            }
                            else {
                                Text("LAUNCHER_NO_SAVED_ACCOUNTS")
                            }
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                        .frame(maxWidth: 45)
                    }

                    HStack {
                        Text("LAUNCHER_SE_PASSWORD")
                            .frame(alignment: .leading)
                        Spacer()
                    }
                    SecureField("LAUNCHER_SE_PASSWORD_PLACEHOLDER", text: $launchController.currentPassword)

                    HStack {
                        Text("LAUNCHER_SE_OTP")
                            .frame(alignment: .leading)
                        Spacer()
                    }
                    .onAppear {
                        launchController.setupOTP()
                    }
                    TextField("LAUNCHER_SE_OTP_PLACEHOLDER", text: $launchController.currentOTPValue)

                    HStack {
                        Toggle(isOn: $autoLogin) {
                            Text("LAUNCHER_AUTOLOGIN")
                        }
                        .padding(.leading)
                        .onChange(of: autoLogin) { newValue in
                            Settings.autoLogin = newValue
                            if newValue {
                                let alert: NSAlert = .init()
                                alert.messageText = NSLocalizedString("AUTOLOGIN_MESSAGE", comment: "")
                                alert.informativeText = NSLocalizedString("AUTOLOGIN_INFORMATIVE", comment: "")
                                alert.alertStyle = .informational
                                alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))

                                alert.runModal()
                            }
                        }

                        Toggle(isOn: $autoOTP) {
                            Text("LAUNCHER_AUTOOTP")
                        }
                        .padding(.leading)
                        .onChange(of: autoOTP) { newValue in
                            Settings.usesOneTimePassword = newValue
                            if newValue && launchController.currentUsername.count > 0 {
                                OTP.getOTPSecretIfNeeded(username: launchController.currentUsername)
                            }
                            launchController.enableOTP()
                        }
                    }
                    Button(action: {
                        launchController.doLogin(repair: false)
                    }) {
                        Text("LAUNCHER_LOGIN_BUTTON")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .disabled(!launchController.loginAllowed)
                    }
                    Spacer()
                }
                .padding()
            }
            // End of Upper Half
            // Start of "News" section
            HStack {
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach($launchController.news) { $oneTopic in
                            HStack {
                                Image(nsImage: NSImage(systemSymbolName: "newspaper", accessibilityDescription: nil)!)
                                Text(oneTopic.title)
                                    .onTapGesture {
                                        if let seURL = oneTopic.usableURL {
                                            openURL(seURL)
                                        }
                                    }
                            }
                        }
                    }
                }
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach($launchController.topics) { $oneTopic in
                            HStack {
                                Image(nsImage: NSImage(systemSymbolName: "newspaper.fill", accessibilityDescription: nil)!)
                                Text(oneTopic.title)
                                    .onTapGesture {
                                        if let seURL = URL(string: oneTopic.url) {
                                            openURL(seURL)
                                        }
                                    }
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .frame(width: 955.0, height: 439.0)
        .focusable()
        .touchBar {
            if showingTouchbarAddons {
                Button(action: {
                    showingTouchbarAddons = false
                }) {
                    Image(systemName: "chevron.backward.square")
                        .imageScale(.large)
                }
                Button("TOUCHBAR_ADDON_ANAMNESIS") {
                    appDelegate.startAnamnesis(self)
                }
                Button("TOUCHBAR_ADDON_IINACT") {
                    appDelegate.startIINACT(self)
                }
                Button("TOUCHBAR_ADDON_ACT") {
                    appDelegate.startACT(self)
                }
                Button("TOUCHBAR_ADDON_BUNNYHUD") {
                    appDelegate.startBH(self)
                }
            }
            else {
                Button("LAUNCHER_LOGIN_BUTTON") {
                    launchController.doLogin(repair: false)
                }
                Button(action: {
                    showingTouchbarAddons = true
                }) {
                    Image(systemName: "puzzlepiece.fill")
                        .imageScale(.large)
                    Text("TOUCHBAR_ADDONS_BUTTON")
                }
                Button(action: {
                    // TODO:
                }) {
                    Image(systemName: "gear")
                        .imageScale(.large)
                    Text("TOUCHBAR_TROUBLESHOOTING_BUTTON")
                }
                Spacer().frame(width: chocoWalkOffset + (chocoFacing ? 20 : 0)) // When we mirror the chocobo, it flips along his origin. So we need to offset him by his width.
                Image(nsImage: NSImage(named: chocoWalkFrame == 0 ? "ChocoboWalk1" : "ChocoboWalk2")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onReceive(self.chocoWalkTimer) { _ in
                        chocoWalkFrame = (chocoWalkFrame + 1) % 2

                        // Turn around if we've hit a boundary
                        if !chocoFacing && chocoWalkOffset < 1 {
                            chocoFacing = true
                        }
                        else if chocoFacing && chocoWalkOffset >= 50 {
                            chocoFacing = false
                        }
                        if !chocoFacing {
                            chocoWalkOffset -= 3
                        }
                        else {
                            chocoWalkOffset += 3
                        }
                    }
                    // Flip the Chocobo image to face the other way if needed
                    .transformEffect(CGAffineTransform(scaleX: chocoFacing ? -1 : 1, y: 1))
            }
        }
        .sheet(isPresented: showSheetBinding) {
            if launchController.installerController.installing {
                InstallerSheetContent()
            }
            else if launchController.patchController.patching {
                PatchingSheetContent()
            }
            else if launchController.repairController.repairing {
                RepairingSheetContent()
            }
            else { // launchContoller.loggingIn, just use it as a last resort too.
                LoginSheetContent()
            }
        }
    }
}

struct LaunchWindowContent_Previews: PreviewProvider {
    static var previews: some View {
        LaunchWindowContent()
            .environmentObject(LaunchController())
    }
}
