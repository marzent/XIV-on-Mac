//
//  SettingsWindow.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/14/23.
//

import SwiftUI

struct SettingsView: View {
    @State private var selectedSettingsTab: SettingsTabItem = .General

    private var generalTabView: SettingsGeneralTabView = .init()
    private var captureView: SettingsCaptureView = .init()
    private var graphicsTabView: SettingsGraphicsTabView = .init()
    private var pluginsTabView: SettingsPluginsTabView = .init()
    private var advancedTabView: SettingsAdvancedTabView = .init()

    var body: some View {
        TabView(selection: $selectedSettingsTab) {
            generalTabView.tabItem { Text("SETTINGS_TAB_GENERAL_TITLE") }.tag(
                SettingsTabItem.General)
            captureView.tabItem { Text("SETTINGS_TAB_CAPTURE_TITLE") }.tag(
                SettingsTabItem.Capture)
            graphicsTabView.tabItem { Text("SETTINGS_TAB_GRAPHICS_TITLE") }.tag(
                SettingsTabItem.Graphics)
            pluginsTabView.tabItem { Text("SETTINGS_TAB_PLUGINS_TITLE") }.tag(
                SettingsTabItem.Plugins)
            advancedTabView.tabItem { Text("SETTINGS_TAB_ADVANCED_TITLE") }.tag(
                SettingsTabItem.Advanced)
        }
        .padding(.top)
        .frame(minWidth: 720, minHeight: 590)
        .background(VisualEffectView())
    }
}

struct SettingsWindow_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

private enum SettingsTabItem: Hashable {
    case General
    case Capture
    case Graphics
    case Plugins
    case Advanced
}
