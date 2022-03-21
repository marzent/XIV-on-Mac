//
//  SettingsController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 27.12.21.
//

import Cocoa
import SeeURL

class SettingsController: NSViewController {
    @IBOutlet private var language: NSPopUpButton!
    @IBOutlet private var license: NSPopUpButton!
    @IBOutlet private var freeTrial: NSButton!
    
    @IBOutlet private var maxDownload: NSButton!
    @IBOutlet private var maxDownloadField: NSTextField!
    @IBOutlet private var keepPatches: NSButton!
    
    @IBOutlet private var devinfo: NSButton!
    @IBOutlet private var fps: NSButton!
    @IBOutlet private var frametimes: NSButton!
    @IBOutlet private var submissions: NSButton!
    @IBOutlet private var drawcalls: NSButton!
    @IBOutlet private var pipelines: NSButton!
    @IBOutlet private var memory: NSButton!
    @IBOutlet private var gpuload: NSButton!
    @IBOutlet private var version: NSButton!
    @IBOutlet private var api: NSButton!
    @IBOutlet private var compiler: NSButton!
    @IBOutlet private var scale: NSSlider!
    @IBOutlet private var maxFPS: NSButton!
    @IBOutlet private var maxFPSField: NSTextField!
    @IBOutlet private var async: NSButton!
    
    @IBOutlet private var esync: NSButton!
    @IBOutlet private var wineDebugField: NSTextField!
    @IBOutlet private var wineRetina: NSButton!
    
    @IBOutlet private var dalamud: NSButton!
    @IBOutlet private var delay: NSTextField!
    @IBOutlet private var crowdSource: NSButton!
    
    @IBOutlet weak var discord: NSButton!
    
    private var mapping: [String : NSButton] = [:]
    
    override func viewDidAppear() {
        super.viewDidAppear()
        mapping = ["devinfo": devinfo, //Displays the name of the GPU and the driver version.
                   "fps": fps, //Shows the current frame rate.
                   "frametimes": frametimes, //Shows a frame time graph.
                   "submissions": submissions, //Shows the number of command buffers submitted per frame.
                   "drawcalls": drawcalls, //Shows the number of draw calls and render passes per frame.
                   "pipelines": pipelines, //Shows the total number of graphics and compute pipelines.
                   "memory": memory, //Shows the amount of device memory allocated and used.
                   "gpuload": gpuload, //Shows estimated GPU load. May be inaccurate.
                   "version": version, //Shows DXVK version.
                   "api": api, //Shows the D3D feature level used by the application.
                   "compiler": compiler] //Shows shader compiler activity
        updateView()
    }
    
    @IBAction func saveState(_ sender: Any) {
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }
    
    @IBAction func resetScale(_ sender: Any) {
        scale.doubleValue = 1.0
        saveState()
    }
    
    @IBAction func selectFull(_ sender: Any) {
        for (_, button) in mapping {
            button.state = NSControl.StateValue.on
        }
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }
    
    @IBAction func selectNone(_ sender: Any) {
        for (_, button) in mapping {
            button.state = NSControl.StateValue.off
        }
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }
    
    @IBAction func updateMaxFPS(_ sender: Any) {
        let button = sender as! NSButton
        maxFPSField.isEnabled = (button.state == NSControl.StateValue.on) ? true : false
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }
    
    @IBAction func updateMaxDownload(_ sender: Any) {
        let button = sender as! NSButton
        maxDownloadField.isEnabled = (button.state == NSControl.StateValue.on) ? true : false
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }
    
    @IBAction func updateRetina(_ sender: NSButton) {
        Wine.retina = (sender.state == NSControl.StateValue.on)
    }
    
    func updateView() {
        for (option, enabled) in DXVK.options.hud {
            mapping[option]?.state = enabled ? NSControl.StateValue.on : NSControl.StateValue.off
        }
        async.state = DXVK.options.async ? NSControl.StateValue.on : NSControl.StateValue.off
        let limited = DXVK.options.maxFramerate != 0
        maxFPS.state = limited ? NSControl.StateValue.on : NSControl.StateValue.off
        maxFPSField.isEnabled = limited
        maxFPSField.stringValue = String(DXVK.options.maxFramerate)
        scale.doubleValue = DXVK.options.hudScale
        
        discord.state = SocialIntegration.discord.enabled ? NSControl.StateValue.on : NSControl.StateValue.off
        
        esync.state = Wine.esync ? NSControl.StateValue.on : NSControl.StateValue.off
        wineRetina.state = Wine.retina ? NSControl.StateValue.on : NSControl.StateValue.off
        wineDebugField.stringValue = Wine.debug
        
        dalamud.state = FFXIVSettings.dalamud ? NSControl.StateValue.on : NSControl.StateValue.off
        crowdSource.state = Dalamud.mbCollection ? NSControl.StateValue.on : NSControl.StateValue.off
        delay.stringValue = "\(Dalamud.delay)"
        
        language.selectItem(at: Int(FFXIVSettings.language.rawValue))
        license.selectItem(at: Int(FFXIVSettings.platform.rawValue))
        freeTrial.state = FFXIVSettings.freeTrial ? NSControl.StateValue.on : NSControl.StateValue.off
        
        let limitedDown = HTTPClient.maxSpeed > 0
        maxDownload.state = limitedDown ? NSControl.StateValue.on : NSControl.StateValue.off
        maxDownloadField.isEnabled = limitedDown
        maxDownloadField.stringValue = String(HTTPClient.maxSpeed)
        keepPatches.state = Patch.keep ? NSControl.StateValue.on : NSControl.StateValue.off
    }
    
    func saveState() {
        DispatchQueue.main.async { [self] in
            for (name, button) in mapping {
                DXVK.options.hud[name] = (button.state == NSControl.StateValue.on) ? true : false
            }
            DXVK.options.async = (async.state == NSControl.StateValue.on) ? true : false
            DXVK.options.maxFramerate = maxFPSField.isEnabled ? Int(maxFPSField.stringValue) ?? 0 : 0
            DXVK.options.hudScale = scale.doubleValue
            DXVK.options.save()
            
            Wine.esync = (esync.state == NSControl.StateValue.on) ? true : false
            Wine.debug = wineDebugField.stringValue
            
            SocialIntegration.discord.enabled = (discord.state == NSControl.StateValue.on) ? true : false
            SocialIntegration.discord.save()
            
            FFXIVSettings.dalamud = (dalamud.state == NSControl.StateValue.on) ? true : false
            Dalamud.mbCollection = (crowdSource.state == NSControl.StateValue.on) ? true : false
            Dalamud.delay = Double(delay.stringValue) ?? Dalamud.defaultInjectionDelay
            
            FFXIVSettings.language = FFXIVLanguage(rawValue: UInt32(language.indexOfSelectedItem)) ?? .english
            FFXIVSettings.platform = FFXIVPlatform(rawValue: UInt32(license.indexOfSelectedItem)) ?? .mac
            FFXIVSettings.freeTrial = (freeTrial.state == NSControl.StateValue.on) ? true : false
            
            HTTPClient.maxSpeed = maxDownloadField.isEnabled ? Double(maxDownloadField.stringValue) ?? 0.0 : 0.0
            Patch.keep = (keepPatches.state == NSControl.StateValue.on) ? true : false
        }
    }

}
