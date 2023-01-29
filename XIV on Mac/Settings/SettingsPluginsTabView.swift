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
                Toggle(isOn: $viewModel.dalamudEnabled) {
                    Text("SETTINGS_PLUGINS_DALAMUD_ENABLE")
                }
                .padding(.leading)
                Spacer()
            }
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
            Divider()
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
        @Published var dalamudEnabled: Bool = Settings.dalamudEnabled {
            didSet { Settings.dalamudEnabled = dalamudEnabled }
        }

        @Published var dalamudDelay: String = .init(Settings.injectionDelay) {
            didSet { Settings.injectionDelay = Double(dalamudDelay) ?? 0 }
        }

        @Published var discordBridge: Bool = DiscordBridge.enabled {
            didSet { DiscordBridge.enabled = discordBridge }
        }
    }
}
