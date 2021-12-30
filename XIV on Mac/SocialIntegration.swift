//
//  SocialIntegration.swift
//  XIV on Mac
//
//  Created by Ming Quah on 29/12/2021.
//

import Foundation
import SwordRPC

struct SocialIntegration {
    class DiscordRichPresence {
        let settingsKey = "DISCORD_OPTIONS"
        var discordAppId = "925647215421173820"
        var iconName = "appicon-alpha"
        var defaults = UserDefaults.standard
        var connected = false
        
        var rpc:SwordRPC
        var richPresence:RichPresence
        var enabled:Bool
        init() {
            if (defaults.object(forKey: settingsKey) == nil) {
                defaults.set(true, forKey: settingsKey)
            }
            self.enabled = defaults.bool(forKey: settingsKey)
            self.rpc = SwordRPC.init(appId: discordAppId)
            self.richPresence = RichPresence()
            
            if (self.enabled) {
                self.connected = connect(rpc: self.rpc)
            } else {
                self.connected = false
            }
        }
        
        func setPresence() {
            if (!self.connected) {
                print("Discord not connected.")
                return;
            }
            
            self.richPresence.assets.largeImage = iconName
            self.richPresence.timestamps.start = Date()
            rpc.setPresence(self.richPresence)
        }
        
        func connect(rpc: SwordRPC) -> Bool {
            return rpc.connect()
        }
        
        func disconnect() -> Bool {
            self.rpc.disconnect()
            return false;
        }
        
        func save() {
            defaults.set(self.enabled, forKey: settingsKey)
            
            if (self.enabled) {
                self.rpc = SwordRPC.init(appId: discordAppId)
                self.connected = connect(rpc: self.rpc)
                setPresence()
            } else {
                self.connected = disconnect()
            }
        }
    }
    
    static var discord = DiscordRichPresence()
}
