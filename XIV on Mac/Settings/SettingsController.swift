//
//  SettingsController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 27.12.21.
//

import Cocoa

protocol SettingsControllerProtocol: NSViewController {
    
    func saveState(_ sender: Any)
    
    func saveState()
    
    func updateView()
    
}

class SettingsControllerClass: NSViewController {
    
    override func viewDidAppear() {
        super.viewDidAppear()
        updateView()
    }
    
    open func updateView() {
        fatalError("updateView() not implemented")
    }
    
}

typealias SettingsController = SettingsControllerClass & SettingsControllerProtocol
