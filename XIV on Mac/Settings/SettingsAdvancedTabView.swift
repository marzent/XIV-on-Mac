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
        VStack(spacing: 18) {
            SettingsSection(title: "Runtime", symbol: "gearshape.2") {
                Text("SETTINGS_ADVANCED_BLURB").foregroundStyle(.secondary)
                Toggle(
                    "SETTINGS_ADVANCED_KEEP_PATCHES",
                    isOn: $viewModel.keepPatches)
                Toggle("SETTINGS_ADVANCED_MSYNC", isOn: $viewModel.mSync)
                Toggle(
                    "SETTINGS_ADVANCED_ENCRYPT_ARGS",
                    isOn: $viewModel.encryptArgs)
            }
            SettingsSection(title: "Game session", symbol: "gamecontroller") {
                Toggle(
                    "SETTINGS_ADVANCED_AUTO_EXIT", isOn: $viewModel.exitWithGame
                )
                Toggle(
                    "SETTINGS_ADVANCED_ERROR_EXIT",
                    isOn: $viewModel.nonZeroExitError)
                Toggle(
                    "SETTINGS_ADVANCED_GAME_CONTROLLER_FRAMEWORK",
                    isOn: $viewModel.gameControllerFramework)
            }
            SettingsSection(title: "Diagnostics", symbol: "terminal") {
                TextField(
                    "SETTINGS_ADVANCED_WINE_DEBUG", text: $viewModel.wineDebug
                )
                .textFieldStyle(.roundedBorder).disableAutocorrection(true)
            }
        }
    }
}

#if DEBUG
    #Preview("Advanced") {
        ScrollView {
            SettingsAdvancedTabView().padding(28)
        }
        .frame(width: 755, height: 640)
        .tint(XOMStyle.accent)
    }
#endif

extension SettingsAdvancedTabView {
    @MainActor class ViewModel: ObservableObject {
        @Published var keepPatches: Bool = Patch.keep {
            didSet { Patch.keep = keepPatches }
        }

        @Published var mSync: Bool = Wine.msync {
            didSet { Wine.msync = mSync }
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

        @Published var gameControllerFramework: Bool = Wine
            .gameControllerFramework
        {
            didSet { Wine.gameControllerFramework = gameControllerFramework }
        }

        @Published var wineDebug: String = Wine.debug {
            didSet { Wine.debug = wineDebug }
        }
    }
}
