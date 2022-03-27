//
//  LaunchWindowController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 27.03.22.
//

import AppKit

class LaunchWindowController: NSWindowController {
    private let autosaveName = "XOMMainWindowPosition"
    
    override func windowDidLoad() {
        super.windowDidLoad()
        if let currentAutosaveName = window?.frameAutosaveName, currentAutosaveName != autosaveName {
            window?.setFrameUsingName(autosaveName)
            window?.setFrameAutosaveName(autosaveName)
        }
        window?.isMovableByWindowBackground = true
    }
    
}
