//
//  SettingsPluginsTabView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/14/23.
//

import SwiftUI

struct SettingsPluginsTabView: View {
    @State var dalamudEnabled: Bool = Settings.dalamudEnabled
    @State var dalamudDelay: String = .init(Settings.injectionDelay)
    @State var discordBridge: Bool = DiscordBridge.enabled
    
    var body: some View {
        VStack {
            Text("SETTINGS_PLUGINS_WHAT_IS_DALAMUD_BLURB")
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .padding([.top, .leading, .trailing])
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Toggle(isOn: $dalamudEnabled) {
                    Text("SETTINGS_PLUGINS_DALAMUD_ENABLE")
                }
                .padding(.leading)
                .onChange(of: dalamudEnabled) { newValue in
                    Settings.dalamudEnabled = newValue
                }
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
                TextField("0", text: $dalamudDelay)
                    .frame(minWidth: 50)
                    .fixedSize(horizontal: true, vertical: false)
                    
                    .onChange(of: dalamudDelay) { newValue in
                        Settings.injectionDelay = Double(newValue) ?? 0
                    }
                
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
                Toggle(isOn: $discordBridge) {
                    Text("SETTINGS_PLUGINS_DISCORD_TOGGLE")
                }
                .padding(.leading)
                .onChange(of: discordBridge) { newValue in
                    DiscordBridge.enabled = newValue
                }
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
