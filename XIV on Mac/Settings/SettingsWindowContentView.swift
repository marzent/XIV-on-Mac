//
//  SettingsWindow.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/14/23.
//

import SwiftUI

struct SettingsWindowContentView: View
{
    @State var selectedSettingsTab : SettingsTabItem = .General
    
    private var generalTabView : SettingsGeneralTabView = SettingsGeneralTabView()
    private var graphicsTabView : SettingsGraphicsTabView = SettingsGraphicsTabView()
    private var pluginsTabView : SettingsPluginsTabView = SettingsPluginsTabView()
    private var advancedTabView : SettingsAdvancedTabView = SettingsAdvancedTabView()

    var body: some View
    {
        TabView(selection: $selectedSettingsTab)
        {
            generalTabView.tabItem { Text("SETTINGS_TAB_GENERAL_TITLE") }.tag(SettingsTabItem.General)
            graphicsTabView.tabItem { Text("SETTINGS_TAB_GRAPHICS_TITLE") }.tag(SettingsTabItem.Graphics)
            pluginsTabView.tabItem { Text("SETTINGS_TAB_PLUGINS_TITLE") }.tag(SettingsTabItem.Plugins)
            advancedTabView.tabItem { Text("SETTINGS_TAB_ADVANCED_TITLE") }.tag(SettingsTabItem.Advanced)
        }
        .padding(.top)
    }
}

struct SettingsWindow_Previews: PreviewProvider {
    static var previews: some View {
        SettingsWindowContentView()
    }
}

enum SettingsTabItem: Hashable
{
    case General
    case Graphics
    case Plugins
    case Advanced
}
