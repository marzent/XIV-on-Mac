//
//  SettingsGeneralTabView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/14/23.
//

import SeeURL  // HTTPClient/Download speed limiter setting
import SwiftUI

struct SettingsGeneralTabView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack {
                VStack {
                    HStack {
                        Text("SETTINGS_GENERAL_TITLE_LICENSE")
                            .font(.headline)

                        Spacer()
                    }

                    Text("SETTINGS_GENERAL_LANGUAGE_AND_LICENSE_BLURB")
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.callout)

                    HStack {
                        Picker(
                            selection: $viewModel.language,
                            label: Text("SETTINGS_LANGUAGE_PICKER")
                        ) {
                            Text("SETTINGS_LANGUAGE_JAPANESE").tag(
                                FFXIVLanguage.japanese)
                            Text("SETTINGS_LANGUAGE_ENGLISH").tag(
                                FFXIVLanguage.english)
                            Text("SETTINGS_LANGUAGE_FRENCH").tag(
                                FFXIVLanguage.french)
                            Text("SETTINGS_LANGUAGE_GERMAN").tag(
                                FFXIVLanguage.german)
                        }
                        .padding(.bottom)
                        .fixedSize(horizontal: true, vertical: false)
                        .disabled(true)

                        Picker(
                            selection: $viewModel.platform,
                            label: Text("SETTINGS_PLATFORM_PICKER")
                        ) {
                            Text("SETTINGS_PLATFORM_MAC").tag(FFXIVPlatform.mac)
                            Text("SETTINGS_PLATFORM_WINDOWS").tag(
                                FFXIVPlatform.windows)
                            Text("SETTINGS_PLATFORM_STEAM").tag(
                                FFXIVPlatform.steam)
                        }
                        .padding(.bottom)
                        .fixedSize(horizontal: true, vertical: false)
                        .disabled(true)

                        Spacer()
                    }

                    HStack {
                        Toggle(isOn: $viewModel.freeTrial) {
                            Text("SETTINGS_FREE_TRIAL")
                        }
                        .fixedSize(horizontal: true, vertical: false)

                        Spacer()
                    }

                    Text("SETTINGS_GENERAL_FREE_TRIAL_BLURB")
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.callout)
                }
                .padding([.leading, .trailing, .top])

                VStack {
                    HStack {
                        Text("SETTINGS_GENERAL_TITLE_NETWORK")
                            .font(.headline)

                        Spacer()
                    }

                    HStack {
                        Toggle(isOn: $viewModel.limitDownloadEnabled) {
                            Text("SETTINGS_DOWNLOAD_LIMIT")
                        }

                        TextField(
                            "SETTINGS_DOWNLOAD_LIMIT_PLACEHOLDER",
                            text: $viewModel.limitDownloadSpeed
                        )
                        .fixedSize(horizontal: true, vertical: false)
                        .disabled(!viewModel.limitDownloadEnabled)

                        Text("SETTINGS_DOWNLOAD_LIMIT_UNITS")
                        Spacer()
                    }
                }
                .padding([.leading, .trailing, .top])

                HStack {
                    VStack {
                        HStack {
                            Text("SETTINGS_GENERAL_TITLE_INPUT")
                                .font(.headline)

                            Spacer()
                        }

                        HStack {
                            Picker(
                                "SETTINGS_GENERAL_INPUT_LEFT_OPTION",
                                selection: $viewModel.leftOptionIsAlt
                            ) {
                                Text(
                                    "SETTINGS_GENERAL_INPUT_BUTTON_WINDOWS_ALT"
                                ).tag(true)
                                Text(
                                    "SETTINGS_GENERAL_INPUT_BUTTON_MACOS_OPTION"
                                ).tag(false)
                            }

                            Picker(
                                "SETTINGS_GENERAL_INPUT_RIGHT_OPTION",
                                selection: $viewModel.rightOptionIsAlt
                            ) {
                                Text(
                                    "SETTINGS_GENERAL_INPUT_BUTTON_WINDOWS_ALT"
                                ).tag(true)
                                Text(
                                    "SETTINGS_GENERAL_INPUT_BUTTON_MACOS_OPTION"
                                ).tag(false)
                            }
                        }

                        HStack {
                            Picker(
                                "SETTINGS_GENERAL_INPUT_LEFT_COMMAND",
                                selection: $viewModel.leftCommandIsCtrl
                            ) {
                                Text("SETTINGS_GENERAL_INPUT_BUTTON_CTRL").tag(
                                    true)
                                Text("SETTINGS_GENERAL_INPUT_BUTTON_ALT").tag(
                                    false)
                            }

                            Picker(
                                "SETTINGS_GENERAL_INPUT_RIGHT_COMMAND",
                                selection: $viewModel.rightCommandIsCtrl
                            ) {
                                Text("SETTINGS_GENERAL_INPUT_BUTTON_CTRL").tag(
                                    true)
                                Text("SETTINGS_GENERAL_INPUT_BUTTON_ALT").tag(
                                    false)
                            }
                        }
                    }

                    Spacer(minLength: 140)
                }
                .padding([.leading, .trailing, .top])

                Spacer()
            }
            Image(nsImage: NSImage(named: "PrefsGeneral") ?? NSImage())
                .padding()
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
        @Published var language: FFXIVLanguage = .english {
            didSet { Settings.language = language }
        }

        @Published var platform: FFXIVPlatform = .windows {
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

        @Published var leftOptionIsAlt: Bool = Wine.leftOptionIsAlt {
            didSet { Wine.leftOptionIsAlt = leftOptionIsAlt }
        }

        @Published var rightOptionIsAlt: Bool = Wine.rightOptionIsAlt {
            didSet { Wine.rightOptionIsAlt = rightOptionIsAlt }
        }

        @Published var leftCommandIsCtrl: Bool = Wine.leftCommandIsCtrl {
            didSet { Wine.leftCommandIsCtrl = leftCommandIsCtrl }
        }

        @Published var rightCommandIsCtrl: Bool = Wine.rightCommandIsCtrl {
            didSet { Wine.rightCommandIsCtrl = rightCommandIsCtrl }
        }

        private func updateHTTPMaxSpeed() {
            HTTPClient.maxSpeed =
                limitDownloadEnabled ? Double(limitDownloadSpeed) ?? 0.0 : 0.0
        }
    }
}
