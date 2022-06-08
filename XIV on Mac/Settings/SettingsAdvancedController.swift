//
//  SettingsAdvancedController.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/30/22.
//

import Cocoa

class SettingsAdvancedController: SettingsController {

    @IBOutlet private var keepPatches: NSButton!
    @IBOutlet private var esync: NSButton!
    @IBOutlet private var encrypted: NSButton!
    @IBOutlet private var wineDebugField: NSTextField!
 
    override func updateView() {
        keepPatches.state = Patch.keep ? NSControl.StateValue.on : NSControl.StateValue.off
        esync.state = Wine.esync ? NSControl.StateValue.on : NSControl.StateValue.off
        encrypted.state = Settings.encryptedArguments ? NSControl.StateValue.on : NSControl.StateValue.off
        
        wineDebugField.stringValue = Wine.debug
    }
    
    @IBAction func saveState(_ sender: Any) {
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }
    
    func saveState() {
        DispatchQueue.main.async { [self] in
            Wine.esync = esync.state == NSControl.StateValue.on
            Wine.debug = wineDebugField.stringValue
            Patch.keep = keepPatches.state == NSControl.StateValue.on
            Settings.encryptedArguments = encrypted.state == NSControl.StateValue.on
        }
    }

}
