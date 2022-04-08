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

class FadingScrollView: NSScrollView {
    let fadePercentage: Float = 0.05

    override func layout() {
        super.layout()
        let transparent = NSColor.clear.cgColor
        let opaque = NSColor.black.cgColor
        let maskLayer = CALayer()
        maskLayer.frame = self.bounds
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = NSMakeRect(self.bounds.origin.x, 0, self.bounds.size.width, self.bounds.size.height)
        gradientLayer.colors = [transparent, opaque, opaque, transparent]
        gradientLayer.locations = [0, NSNumber(value: fadePercentage), NSNumber(value: 1 - fadePercentage * 2), 1]
        maskLayer.addSublayer(gradientLayer)
        self.layer?.mask = maskLayer
    }
}
