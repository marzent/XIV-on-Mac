//
//  SettingsGeneralTabView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/14/23.
//

import SwiftUI
import SeeURL // HTTPClient/Download speed limiter setting

struct SettingsGeneralTabView: View
{
    @State var language : FFXIVLanguage = Settings.language
    @State var platform : FFXIVPlatform = Settings.platform
    @State var freeTrial : Bool = Settings.freeTrial
    @State var limitDownloadEnabled : Bool = HTTPClient.maxSpeed > 0
    @State var limitDownloadSpeed : String = String(HTTPClient.maxSpeed)
    
    var body: some View
    {
        VStack
        {
            Text("SETTINGS_GENERAL_LANGUAGE_AND_LICENSE_BLURB")
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .padding([.top, .leading, .trailing])
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack
            {
                Picker(selection: $language, label: Text("SETTINGS_LANGUAGE_PICKER"))
                {
                    Text("SETTINGS_LANGUAGE_JAPANESE").tag(FFXIVLanguage.japanese)
                    Text("SETTINGS_LANGUAGE_ENGLISH").tag(FFXIVLanguage.english)
                    Text("SETTINGS_LANGUAGE_FRENCH").tag(FFXIVLanguage.french)
                    Text("SETTINGS_LANGUAGE_GERMAN").tag(FFXIVLanguage.german)
                }
                .padding([.leading, .bottom,.trailing])
                    .fixedSize(horizontal: true, vertical: false)
                    .onChange(of: language)
                    { newValue in
                        Settings.language = newValue
                    }
                
                
                Picker(selection: $platform, label: Text("SETTINGS_PLATFORM_PICKER"))
                {
                    Text("SETTINGS_PLATFORM_MAC").tag(FFXIVPlatform.mac)
                    Text("SETTINGS_PLATFORM_WINDOWS").tag(FFXIVPlatform.windows)
                    Text("SETTINGS_PLATFORM_STEAM").tag(FFXIVPlatform.steam)
                }
                .padding([.leading, .bottom,.trailing])
                    .fixedSize(horizontal: true, vertical: false)
                    .onChange(of: platform)
                    { newValue in
                        Settings.platform = newValue
                    }

                Spacer()
            }

            HStack
            {
                Toggle(isOn: $freeTrial)
                {
                    Text("SETTINGS_FREE_TRIAL")
                }
                    .padding(.leading)
                    .onChange(of: freeTrial)
                    { newValue in
                        Settings.freeTrial = newValue
                    }
                Spacer()
            }
            
            Text("SETTINGS_GENERAL_FREE_TRIAL_BLURB")
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack
            {
                Toggle(isOn: $limitDownloadEnabled)
                {
                    Text("SETTINGS_DOWNLOAD_LIMIT")
                }
                    .padding(.leading)
                    .onChange(of: limitDownloadEnabled)
                    { newValue in
                        HTTPClient.maxSpeed = newValue ? Double(limitDownloadSpeed) ?? 0.0 : 0.0
                    }
                
                TextField("SETTINGS_DOWNLOAD_LIMIT_PLACEHOLDER", text: $limitDownloadSpeed)
                    .fixedSize(horizontal: true, vertical: false)
                    .disabled(!limitDownloadEnabled)
                    .onChange(of: limitDownloadSpeed)
                    { newValue in
                        HTTPClient.maxSpeed = limitDownloadEnabled ? Double(newValue) ?? 0.0 : 0.0
                    }

                Text("SETTINGS_DOWNLOAD_LIMIT_UNITS")
                Spacer()
                    .padding(.horizontal)

            }
            
            Spacer()
            
            HStack
            {
                Spacer()
                Image(nsImage: NSImage(named: "PrefsGeneral") ?? NSImage())
                    .padding(.all)
            }

        }
        
    }
}

struct SettingsGeneralTabView_Previews: PreviewProvider
{
    static var previews: some View
    {
        SettingsGeneralTabView()
    }
}


