//
//  SettingsGraphicsController.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/30/22.
//

import Cocoa

class SettingsGraphicsController: SettingsController {

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

    @IBOutlet private var wineRetina: NSButton!
    @IBOutlet private var wineRetinaWorkaround: NSButton!
    
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
    
    override func updateView() {
        for (option, enabled) in Dxvk.options.hud {
            mapping[option]?.state = enabled ? NSControl.StateValue.on : NSControl.StateValue.off
        }
        async.state = Dxvk.options.async ? NSControl.StateValue.on : NSControl.StateValue.off
        let limited = Dxvk.options.maxFramerate != 0
        maxFPS.state = limited ? NSControl.StateValue.on : NSControl.StateValue.off
        maxFPSField.isEnabled = limited
        maxFPSField.stringValue = String(Dxvk.options.maxFramerate)
        scale.doubleValue = Dxvk.options.hudScale
        
        wineRetina.state = !Wine.retina ? NSControl.StateValue.on : NSControl.StateValue.off
        wineRetinaWorkaround.state = Wine.retinaStartupBugWorkaround ? NSControl.StateValue.on : NSControl.StateValue.off
        wineRetinaWorkaround.isHidden = !Wine.retina
        
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
        if (sender is NSButton) {
            let button = sender as! NSButton
            maxFPSField.isEnabled = (button.state == NSControl.StateValue.on) ? true : false
        }
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }

    @IBAction func updateRetina(_ sender: NSButton) {
        // Changing to and from retina can confuse the games internal reolution, warn the user about that.
        // The exposed UI option is the opposite of the internal representation in order to avoid user confusion
        let alert: NSAlert = NSAlert()
        alert.messageText = NSLocalizedString("RETINA_WARNING", comment: "")
        alert.informativeText = NSLocalizedString("RETINA_WARNING_INFORMATIVE", comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle:NSLocalizedString("RETINA_ENABLE_BUTTON", comment: ""))
        alert.addButton(withTitle:NSLocalizedString("CANCEL_BUTTON", comment: ""))
        let result = alert.runModal()
        guard result == .alertFirstButtonReturn else {
            wineRetina.state = !Wine.retina ? NSControl.StateValue.on : NSControl.StateValue.off
            return
        }
        Wine.retina = sender.state == NSControl.StateValue.off
        updateView()
    }

    @IBAction func updateRetinaWorkaround(_ sender: NSButton) {
        Wine.retinaStartupBugWorkaround = sender.state == NSControl.StateValue.on;
    }
    
    
    @IBAction func saveState(_ sender: Any) {
        DispatchQueue.global(qos: .utility).async {
            self.saveState()
        }
    }
    
    func saveState() {
        DispatchQueue.main.async { [self] in
            for (name, button) in mapping {
                Dxvk.options.hud[name] = button.state == NSControl.StateValue.on
            }
            Dxvk.options.async = async.state == NSControl.StateValue.on
            Dxvk.options.maxFramerate = maxFPSField.isEnabled ? Int(maxFPSField.stringValue) ?? 0 : 0
            Dxvk.options.hudScale = scale.doubleValue
            Dxvk.options.save()
        }
    }

}
