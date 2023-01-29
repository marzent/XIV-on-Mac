//
//  SettingsGeneralTabView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/14/23.
//

import SeeURL // HTTPClient/Download speed limiter setting
import SwiftUI

struct SettingsGeneralTabView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack {
            Text("SETTINGS_GENERAL_LANGUAGE_AND_LICENSE_BLURB")
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .padding([.top, .leading, .trailing])
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Picker(selection: $viewModel.language, label: Text("SETTINGS_LANGUAGE_PICKER")) {
                    Text("SETTINGS_LANGUAGE_JAPANESE").tag(FFXIVLanguage.japanese)
                    Text("SETTINGS_LANGUAGE_ENGLISH").tag(FFXIVLanguage.english)
                    Text("SETTINGS_LANGUAGE_FRENCH").tag(FFXIVLanguage.french)
                    Text("SETTINGS_LANGUAGE_GERMAN").tag(FFXIVLanguage.german)
                }
                .padding([.leading, .bottom, .trailing])
                .fixedSize(horizontal: true, vertical: false)

                Picker(selection: $viewModel.platform, label: Text("SETTINGS_PLATFORM_PICKER")) {
                    Text("SETTINGS_PLATFORM_MAC").tag(FFXIVPlatform.mac)
                    Text("SETTINGS_PLATFORM_WINDOWS").tag(FFXIVPlatform.windows)
                    Text("SETTINGS_PLATFORM_STEAM").tag(FFXIVPlatform.steam)
                }
                .padding([.leading, .bottom, .trailing])
                .fixedSize(horizontal: true, vertical: false)

                Spacer()
            }

            HStack {
                Toggle(isOn: $viewModel.freeTrial) {
                    Text("SETTINGS_FREE_TRIAL")
                }
                .padding(.leading)
                Spacer()
            }

            Text("SETTINGS_GENERAL_FREE_TRIAL_BLURB")
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Toggle(isOn: $viewModel.limitDownloadEnabled) {
                    Text("SETTINGS_DOWNLOAD_LIMIT")
                }
                .padding(.leading)

                TextField("SETTINGS_DOWNLOAD_LIMIT_PLACEHOLDER", text: $viewModel.limitDownloadSpeed)
                    .fixedSize(horizontal: true, vertical: false)
                    .disabled(!viewModel.limitDownloadEnabled)

                Text("SETTINGS_DOWNLOAD_LIMIT_UNITS")
                Spacer()
                    .padding(.horizontal)
            }

            Spacer()

            HStack {
                Spacer()
                Image(nsImage: NSImage(named: "PrefsGeneral") ?? NSImage())
                    .padding(.all)
            }
        }
    }
}

struct SettingsGeneralTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsGeneralTabView()
    }
}

extension SettingsGeneralTabView {
    @MainActor class ViewModel: ObservableObject {
        @Published var language: FFXIVLanguage = Settings.language {
            didSet { Settings.language = language }
        }

        @Published var platform: FFXIVPlatform = Settings.platform {
            didSet { Settings.platform = platform }
        }

        @Published var freeTrial: Bool = Settings.freeTrial {
            didSet { Settings.freeTrial = freeTrial }
        }

        @Published var limitDownloadEnabled: Bool = HTTPClient.maxSpeed > 0 {
            didSet { updateHTTPMaxSpeed() }
        }

        @Published var limitDownloadSpeed: String = .init(HTTPClient.maxSpeed) {
            didSet { updateHTTPMaxSpeed() }
        }

        private func updateHTTPMaxSpeed() {
            HTTPClient.maxSpeed = limitDownloadEnabled ? Double(limitDownloadSpeed) ?? 0.0 : 0.0
        }
    }
}
