//
//  SettingsPluginsController.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/30/22.
//

import Cocoa

class SettingsPluginsController: SettingsController {

    @IBOutlet private var dalamud: NSButton!
    @IBOutlet private var delay: NSTextField!
    
    @IBOutlet weak var discord: NSButton!

    override func updateView() {
        discord.state = DiscordBridge.enabled ? NSControl.StateValue.on : NSControl.StateValue.off
        
        dalamud.state = Settings.dalamudEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
        delay.stringValue = "\(Settings.injectionDelay)"
    }
    
    @IBAction func saveState(_ sender: Any) {
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }
    
    func saveState() {
        DispatchQueue.main.async { [self] in
            DiscordBridge.enabled = discord.state == NSControl.StateValue.on
            
            Settings.dalamudEnabled = dalamud.state == NSControl.StateValue.on
            Settings.injectionDelay = Double(delay.stringValue) ?? Settings.defaultInjectionDelay
        }
    }
    
}
