//
//  SettingsPluginsTabView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/14/23.
//

import SwiftUI

struct SettingsPluginsTabView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack {
            Text("SETTINGS_PLUGINS_WHAT_IS_DALAMUD_BLURB")
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .padding([.top, .leading, .trailing])
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                // TEMPORARILY DISABLED: Dalamud functionality UI
                // To re-enable: Remove the 'if false' condition below
                if false {
                    Toggle(isOn: $viewModel.dalamudEnabled) {
                        Text("SETTINGS_PLUGINS_DALAMUD_ENABLE")
                    }
                    .padding(.leading)
                }
                Spacer()
                // TEMPORARILY DISABLED: Dalamud entry point functionality UI
                // To re-enable: Remove the 'if false' condition below
                if false {
                    Toggle(isOn: $viewModel.dalamudEntryPoint) {
                        Text("SETTINGS_PLUGINS_DALAMUD_ENTRYPOINT")
                    }
                    .padding(.leading)
                    .disabled(!viewModel.dalamudEnabled)
                }
                Spacer()
            }
            // TEMPORARILY DISABLED: Dalamud delay settings UI
            // To re-enable: Remove the 'if false' condition below
            if false && !viewModel.dalamudEntryPoint {
                Text("SETTINGS_PLUGINS_DALAMUD_DELAY_BLURB")
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .padding([.top, .leading, .trailing])
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text("SETTINGS_PLUGINS_DALAMUD_DELAY_LABEL")
                        .padding([.leading])
                    TextField("0", text: $viewModel.dalamudDelay)
                        .frame(minWidth: 50)
                        .fixedSize(horizontal: true, vertical: false)
                    Text("SETTINGS_PLUGINS_DALAMUD_DELAY_UNITS")
                    Spacer()
                }
            }
            Divider().padding([.top])
            Text("SETTINGS_PLUGINS_DISCORD_BLURB")
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .padding([.top, .leading, .trailing])
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Toggle(isOn: $viewModel.discordBridge) {
                    Text("SETTINGS_PLUGINS_DISCORD_TOGGLE")
                }
                .padding(.leading)
                Spacer()
            }
            Spacer()
        }
    }
}

struct SettingsPluginsTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsPluginsTabView()
    }
}

extension SettingsPluginsTabView {
    @MainActor class ViewModel: ObservableObject {
        // TEMPORARILY DISABLED: Dalamud functionality
        // To re-enable: Change back to 'Settings.dalamudEnabled' and remove UI hiding
        @Published var dalamudEnabled: Bool = false {
            didSet { Settings.dalamudEnabled = dalamudEnabled }
        }

        // TEMPORARILY DISABLED: Dalamud entry point functionality
        // To re-enable: Change back to 'Settings.dalamudEntryPoint'
        @Published var dalamudEntryPoint: Bool = false {
            didSet { Settings.dalamudEntryPoint = dalamudEntryPoint }
        }

        // TEMPORARILY DISABLED: Dalamud delay settings
        // To re-enable: Change back to '.init(Settings.injectionDelay)'
        @Published var dalamudDelay: String = "0" {
            didSet { Settings.injectionDelay = Double(dalamudDelay) ?? 0 }
        }

        @Published var discordBridge: Bool = DiscordBridge.enabled {
            didSet { DiscordBridge.enabled = discordBridge }
        }
    }
}
