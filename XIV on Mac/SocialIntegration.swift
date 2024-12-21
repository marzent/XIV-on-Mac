//
//  SocialIntegration.swift
//  XIV on Mac
//
//  Created by Ming Quah on 29/12/2021.
//

import Foundation

struct DiscordBridge {
    @available(*, unavailable) private init() {}

    private static let bridge = Bundle.main.url(
        forResource: "discord_bridge", withExtension: "exe", subdirectory: "")!

    private static let updateKey = "Discord"
    static var enabled: Bool {
        get {
            return Util.getSetting(settingKey: updateKey, defaultValue: false)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: updateKey)
            setPresence()
        }
    }

    static func setPresence() {
        guard enabled else {
            Wine.taskKill(processName: "discord_bridge.exe")
            return
        }
        Wine.launch(command: "\"\(bridge.path)\"")
    }
}
