//
//  SettingsAdvancedTabView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/14/23.
//

import SwiftUI

struct SettingsAdvancedTabView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack {
            Text("SETTINGS_ADVANCED_BLURB")
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .padding([.top, .leading, .trailing])
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Toggle(isOn: $viewModel.keepPatches) {
                    Text("SETTINGS_ADVANCED_KEEP_PATCHES")
                }
                .padding(.leading)
                Spacer()
            }
            HStack {
                Toggle(isOn: $viewModel.eSync) {
                    Text("SETTINGS_ADVANCED_ESYNC")
                }
                .padding(.leading)
                Spacer()
            }
            HStack {
                Toggle(isOn: $viewModel.encryptArgs) {
                    Text("SETTINGS_ADVANCED_ENCRYPT_ARGS")
                }
                .padding(.leading)
                Spacer()
            }
            HStack {
                Toggle(isOn: $viewModel.exitWithGame) {
                    Text("SETTINGS_ADVANCED_AUTO_EXIT")
                }
                .padding(.leading)
                Spacer()
            }
            HStack {
                Toggle(isOn: $viewModel.nonZeroExitError) {
                    Text("SETTINGS_ADVANCED_ERROR_EXIT")
                }
                .padding(.leading)
                Spacer()
            }
            HStack {
                Text("SETTINGS_ADVANCED_WINE_DEBUG")
                    .padding(.leading)
                TextField("", text: $viewModel.wineDebug)
                    .disableAutocorrection(true)
            }
            Spacer()
        }
    }
}

struct SettingsAdvancedTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAdvancedTabView()
    }
}

extension SettingsAdvancedTabView {
    @MainActor class ViewModel: ObservableObject {
        @Published var keepPatches: Bool = Patch.keep {
            didSet { Patch.keep = keepPatches }
        }

        @Published var eSync: Bool = Wine.esync {
            didSet { Wine.esync = eSync }
        }

        @Published var encryptArgs: Bool = Settings.encryptedArguments {
            didSet { Settings.encryptedArguments = encryptArgs }
        }

        @Published var nonZeroExitError: Bool = Settings.nonZeroExitError {
            didSet { Settings.nonZeroExitError = nonZeroExitError }
        }

        @Published var exitWithGame: Bool = Settings.exitWithGame {
            didSet { Settings.exitWithGame = exitWithGame }
        }

        @Published var wineDebug: String = Wine.debug {
            didSet { Wine.debug = wineDebug }
        }
    }
}
