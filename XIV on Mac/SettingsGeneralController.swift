//
//  SettingsGeneralController.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/30/22.
//

import Cocoa
import SeeURL

class SettingsGeneralController: NSViewController {

    @IBOutlet private var language: NSPopUpButton!
    @IBOutlet private var license: NSPopUpButton!
    @IBOutlet private var freeTrial: NSButton!
    
    @IBOutlet private var maxDownload: NSButton!
    @IBOutlet private var maxDownloadField: NSTextField!

    @IBAction func updateMaxDownload(_ sender: Any) {
        if (sender is NSButton) {
            let button = sender as! NSButton
            maxDownloadField.isEnabled = (button.state == NSControl.StateValue.on) ? true : false
        }
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }
    
    @IBAction func updateLanguage(_ sender: Any) {
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }
    
    @IBAction func updateLicense(_ sender: Any) {
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }
    
    @IBAction func updateFreeTrial(_ sender: Any) {
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        updateView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func saveState() {
        DispatchQueue.main.async {
            FFXIVSettings.language = FFXIVLanguage(rawValue: UInt32(self.language.indexOfSelectedItem)) ?? .english
            FFXIVSettings.platform = FFXIVPlatform(rawValue: UInt32(self.license.indexOfSelectedItem)) ?? .mac
            FFXIVSettings.freeTrial = self.freeTrial.state == NSControl.StateValue.on
            
            HTTPClient.maxSpeed = self.maxDownloadField.isEnabled ? Double(self.maxDownloadField.stringValue) ?? 0.0 : 0.0
        }
    }

    func updateView() {
        language.selectItem(at: Int(FFXIVSettings.language.rawValue))
        license.selectItem(at: Int(FFXIVSettings.platform.rawValue))
        freeTrial.state = FFXIVSettings.freeTrial ? NSControl.StateValue.on : NSControl.StateValue.off
        
        let limitedDown = HTTPClient.maxSpeed > 0
        maxDownload.state = limitedDown ? NSControl.StateValue.on : NSControl.StateValue.off
        maxDownloadField.isEnabled = limitedDown
        maxDownloadField.stringValue = String(HTTPClient.maxSpeed)
    }

    
}
