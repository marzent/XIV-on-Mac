//
//  SettingsGeneralController.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/30/22.
//

import Cocoa
import SeeURL

class SettingsGeneralController: SettingsController {

    @IBOutlet private var language: NSPopUpButton!
    @IBOutlet private var license: NSPopUpButton!
    @IBOutlet private var freeTrial: NSButton!
    
    @IBOutlet private var maxDownload: NSButton!
    @IBOutlet private var maxDownloadField: NSTextField!

    override func updateView() {
        language.selectItem(at: Int(Settings.language.rawValue))
        license.selectItem(at: Int(Settings.platform.rawValue))
        freeTrial.state = Settings.freeTrial ? NSControl.StateValue.on : NSControl.StateValue.off
        
        let limitedDown = HTTPClient.maxSpeed > 0
        maxDownload.state = limitedDown ? NSControl.StateValue.on : NSControl.StateValue.off
        maxDownloadField.isEnabled = limitedDown
        maxDownloadField.stringValue = String(HTTPClient.maxSpeed)
    }
    
    @IBAction func updateMaxDownload(_ sender: Any) {
        if (sender is NSButton) {
            let button = sender as! NSButton
            maxDownloadField.isEnabled = (button.state == NSControl.StateValue.on) ? true : false
        }
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }
    
    @IBAction func saveState(_ sender: Any) {
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }
    
    func saveState() {
        DispatchQueue.main.async {
            Settings.language = FFXIVLanguage(rawValue: UInt8(self.language.indexOfSelectedItem)) ?? .english
            Settings.platform = FFXIVPlatform(rawValue: UInt8(self.license.indexOfSelectedItem)) ?? .mac
            Settings.freeTrial = self.freeTrial.state == NSControl.StateValue.on
            
            HTTPClient.maxSpeed = self.maxDownloadField.isEnabled ? Double(self.maxDownloadField.stringValue) ?? 0.0 : 0.0
        }
    }
    
}
