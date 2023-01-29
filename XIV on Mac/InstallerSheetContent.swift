//
//  InstallerSheetContent.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/22/23.
//

import SwiftUI

struct InstallerSheetContent: View {
    @EnvironmentObject var launchController: LaunchController
    @EnvironmentObject var installerController: InstallerController
    @State var version: VersionSelect = .DalamudDisabled
    @State var license: FFXIVPlatform = .mac
    @State var gameFiles: InstallerController.GameFiles = .download

    enum VersionSelect {
        case DalamudDisabled
        case DalamudEnabled
    }

    func selectOptionSheetContent() -> some View {
        GroupBox(label: Text("INSTALLER_SELECT_OPTION").font(Font.title)) {
            Picker(selection: $version, label: Text("")) {
                VStack {
                    if #available(macOS 13.0, *) {
                        Text("INSTALLER_SELECT_OPTION_DALAMUD_DISABLED")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .bold()
                    }
                    else {
                        Text("INSTALLER_SELECT_OPTION_DALAMUD_DISABLED")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("INSTALLER_SELECT_OPTION_DALAMUD_DISABLED_BLURB")
                        .padding(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.tag(VersionSelect.DalamudDisabled)
                    .fixedSize()
                VStack {
                    if #available(macOS 13.0, *) {
                        Text("INSTALLER_SELECT_OPTION_DALAMUD_ENABLED")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .bold()
                    }
                    else {
                        Text("INSTALLER_SELECT_OPTION_DALAMUD_ENABLED")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("INSTALLER_SELECT_OPTION_DALAMUD_ENABLED_BLURB")
                        .padding(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.tag(VersionSelect.DalamudEnabled)
                    .fixedSize()
            }
            .pickerStyle(.radioGroup)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            HStack {
                Button(action: { installerController.openFAQ(self) }) {
                    Image(systemName: "questionmark.circle").imageScale(.large)
                }.buttonStyle(PlainButtonStyle())
                Spacer()
            }
        }
        .padding([.top, .horizontal])
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    func selectLicenseSheetContent() -> some View {
        GroupBox(label: Text("INSTALLER_SELECT_LICENSE").font(Font.title)) {
            Picker(selection: $license, label: Text("")) {
                VStack {
                    if #available(macOS 13.0, *) {
                        Text("SETTINGS_PLATFORM_MAC")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .bold()
                    }
                    else {
                        Text("SETTINGS_PLATFORM_MAC")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("INSTALLER_SELECT_LICENSE_MAC_BLURB")
                        .padding(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tag(FFXIVPlatform.mac)
                .fixedSize()
                VStack {
                    if #available(macOS 13.0, *) {
                        Text("SETTINGS_PLATFORM_WINDOWS")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .bold()
                    }
                    else {
                        Text("SETTINGS_PLATFORM_WINDOWS")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("INSTALLER_SELECT_LICENSE_WINDOWS_BLURB")
                        .padding(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tag(FFXIVPlatform.windows)
                .fixedSize()
                VStack {
                    if #available(macOS 13.0, *) {
                        Text("SETTINGS_PLATFORM_STEAM")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .bold()
                    }
                    else {
                        Text("SETTINGS_PLATFORM_STEAM")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("INSTALLER_SELECT_LICENSE_STEAM_BLURB")
                        .padding(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tag(FFXIVPlatform.steam)
                .fixedSize()
            }
            .pickerStyle(.radioGroup)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            HStack {
                Button(action: { installerController.openFAQ(self) }) {
                    Image(systemName: "questionmark.circle").imageScale(.large)
                }.buttonStyle(PlainButtonStyle())
                Spacer()
            }
        }
        .padding([.top, .horizontal])
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    func copyGameSheetContent() -> some View {
        GroupBox(label: Text("INSTALLER_GAMEFILES").font(Font.title)) {
            Picker(selection: $gameFiles, label: Text("")) {
                VStack {
                    if #available(macOS 13.0, *) {
                        Text("INSTALLER_GAME_FILES_DOWNLOAD")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .bold()
                    }
                    else {
                        Text("INSTALLER_GAME_FILES_DOWNLOAD")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("INSTALLER_GAME_FILES_DOWNLOAD_BLURB")
                        .padding(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tag(InstallerController.GameFiles.download)
                .fixedSize()
                VStack {
                    if #available(macOS 13.0, *) {
                        Text("INSTALLER_GAME_FILES_COPY")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .bold()
                    }
                    else {
                        Text("INSTALLER_GAME_FILES_COPY")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("INSTALLER_GAME_FILES_COPY_BLURB")
                        .padding(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tag(InstallerController.GameFiles.copy)
                .fixedSize()
                VStack {
                    if #available(macOS 13.0, *) {
                        Text("INSTALLER_GAME_FILES_EXISTING")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .bold()
                    }
                    else {
                        Text("INSTALLER_GAME_FILES_EXISTING")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("INSTALLER_GAME_FILES_EXISTING_BLURB")
                        .padding(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.tag(InstallerController.GameFiles.point)
                    .fixedSize()
            }
            .pickerStyle(.radioGroup)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            HStack {
                Button(action: { installerController.openFAQ(self) }) {
                    Image(systemName: "questionmark.circle").imageScale(.large)
                }.buttonStyle(PlainButtonStyle())
                if gameFiles == InstallerController.GameFiles.point {
                    if #available(macOS 12.0, *) {
                        Text("INSTALLER_GAME_FILES_EXISTING_WARNING").font(Font.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color(nsColor: .systemRed))
                    }
                    else {
                        Text("INSTALLER_GAME_FILES_EXISTING_WARNING").font(Font.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                else {
                    Spacer()
                }
            }
        }
        .padding([.top, .horizontal])
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    func installingSheetContent() -> some View {
        GroupBox(label: Text("INSTALLER_INSTALLING").font(Font.title)) {
            Spacer()
            Text(installerController.status)
                .frame(maxWidth: .infinity)
            Text(installerController.info)
                .frame(maxWidth: .infinity)
            ProgressView("", value: installerController.progress, total: installerController.progressMax)

            Spacer()
            Button(action: { installerController.openFAQ(self) }) {
                Image(systemName: "questionmark.circle").imageScale(.large)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding([.top, .horizontal])
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    func doneSheetContent() -> some View {
        GroupBox(label: Text("INSTALLER_DONE").font(Font.title)) {
            Spacer()
            HStack {
                Image(nsImage: NSImage(named: "PrefsGeneral")!)
                Text("INSTALLER_DONE_WELCOME").font(Font.title)
            }
            Spacer()
            Button(action: { installerController.openFAQ(self) }) {
                Image(systemName: "questionmark.circle").imageScale(.large)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding([.top, .horizontal])
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    /*
     This SHOULD be a nice generic way to remove the boilerplate from these radios, but
     I just cannot figure out the compiler "Type 'any View' cannot conform to 'View' - I don't
     see how this is different from the dozen other places I've done the same thing.

     func installSheetRadioItem(mainLabel:String, blurb: String, tag: any Hashable) -> some View
     {
         return VStack
         {
             if #available(macOS 13.0, *) {
                 Text(LocalizedStringKey(mainLabel))
                     .frame(maxWidth:.infinity,alignment: .leading)
                     .bold()
             }
             else
             {
                 Text(LocalizedStringKey(mainLabel))
                     .frame(maxWidth:.infinity,alignment: .leading)
             }
             Text(LocalizedStringKey(blurb))
                 .padding(.leading)
                 .frame(maxWidth:.infinity,alignment: .leading)
         }.tag(tag)
             .fixedSize()
     }
      */

    func leavingPageForward(leavingPage: InstallerController.InstallerSheetPage) {
        switch leavingPage {
        case .selectOption:
            Settings.dalamudEnabled = version == .DalamudEnabled
        case .selectLicense:
            Settings.platform = license
        case .copyGame:
            installerController.startInstall(self)
        default:
            return
        }
    }

    var body: some View {
        VStack {
            switch $installerController.page.wrappedValue {
            case .selectOption:
                selectOptionSheetContent()
            case .selectLicense:
                selectLicenseSheetContent()
            case .copyGame:
                copyGameSheetContent()
            case .installing:
                installingSheetContent()
            case .done:
                doneSheetContent()
            }
            Spacer()
            HStack {
                if installerController.page == .done {
                    Spacer()
                    Button("BUTTON_CLOSE") {
                        installerController.closeWindow(self)
                    }
                }
                else {
                    Button("BUTTON_CANCEL") {
                        installerController.cancelInstall(self)
                    }
                    Spacer()
                    Button("BUTTON_PREVIOUS") {
                        installerController.previousPage()
                    }
                    .disabled(installerController.page.rawValue == 0)
                    Button("BUTTON_NEXT") {
                        leavingPageForward(leavingPage: installerController.page)
                        installerController.nextPage()
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 713, minHeight: 408)
    }
}

struct InstallerSheetContent_Previews: PreviewProvider {
    static var previews: some View {
        InstallerSheetContent()
            .environmentObject(LaunchController())
            .environmentObject(InstallerController())
    }
}
