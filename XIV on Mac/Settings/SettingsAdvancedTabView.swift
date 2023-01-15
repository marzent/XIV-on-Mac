//
//  SettingsAdvancedTabView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/14/23.
//

import SwiftUI

struct SettingsAdvancedTabView: View
{
    @State var keepPatches : Bool = Patch.keep
    @State var eSync : Bool = Wine.esync
    @State var encryptArgs : Bool = Settings.encryptedArguments
    @State var nonZeroExitError : Bool = Settings.nonZeroExitError
    @State var exitWithGame : Bool = Settings.exitWithGame
    @State var wineDebug : String = Wine.debug
    
    var body: some View
    {
        VStack
        {
            Text("SETTINGS_ADVANCED_BLURB")
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .padding([.top, .leading, .trailing])
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack
            {
                Toggle(isOn: $keepPatches)
                {
                    Text("SETTINGS_ADVANCED_KEEP_PATCHES")
                }
                .padding(.leading)
                .onChange(of: keepPatches)
                { newValue in
                    Patch.keep = newValue
                }
                Spacer()
            }
            HStack
            {
                Toggle(isOn: $eSync)
                {
                    Text("SETTINGS_ADVANCED_ESYNC")
                }
                .padding(.leading)
                .onChange(of: eSync)
                { newValue in
                    Wine.esync = newValue
                }
                Spacer()
            }
            HStack
            {
                Toggle(isOn: $encryptArgs)
                {
                    Text("SETTINGS_ADVANCED_ENCRYPT_ARGS")
                }
                .padding(.leading)
                .onChange(of: encryptArgs)
                { newValue in
                    Settings.encryptedArguments = newValue
                }
                Spacer()
            }
            HStack
            {
                Toggle(isOn: $exitWithGame)
                {
                    Text("SETTINGS_ADVANCED_AUTO_EXIT")
                }
                .padding(.leading)
                .onChange(of: exitWithGame)
                { newValue in
                    Settings.exitWithGame = newValue
                }
                Spacer()
            }
            HStack
            {
                Toggle(isOn: $nonZeroExitError)
                {
                    Text("SETTINGS_ADVANCED_ERROR_EXIT")
                }
                .padding(.leading)
                .onChange(of: nonZeroExitError)
                { newValue in
                    Settings.nonZeroExitError = newValue
                }
                Spacer()
            }
            HStack
            {
                Text("SETTINGS_ADVANCED_WINE_DEBUG")
                    .padding(.leading)
                TextField("", text: $wineDebug)
                    .onChange(of: wineDebug)
                { newValue in
                    Wine.debug = newValue
                }

            }
            Spacer()
        }
    }
}

struct SettingsAdvancedTabView_Previews: PreviewProvider
{
    static var previews: some View
    {
        SettingsAdvancedTabView()
    }
}
