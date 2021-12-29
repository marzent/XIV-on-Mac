//
//  Discord.swift
//  XIV on Mac
//
//  Created by Ming Quah on 29/12/2021.
//

import Foundation
import SwordRPC

class DiscordRichPresence {
    var discordAppId = "925647215421173820"
    var version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "1.0.0"
    var iconName = "appicon"
    
    var rpc:SwordRPC
    var richPresence:RichPresence
    var connected:Bool
    var details:String
    init() {
        self.rpc = SwordRPC.init(appId: discordAppId)
        self.connected = self.rpc.connect()
        self.richPresence = RichPresence()
        self.details = "Version " + version
    }
    
    func setPresence() {
        self.richPresence.assets.largeImage = iconName
        self.richPresence.details = details
        self.richPresence.timestamps.start = Date()
        rpc.setPresence(self.richPresence)
    }
}
