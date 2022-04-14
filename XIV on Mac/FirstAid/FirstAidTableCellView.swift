//
//  FirstAidTableCellView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/12/22.
//

import Cocoa

class FirstAidTableCellView: NSTableCellView {

    @IBOutlet weak var problemTitleLabel: NSTextField!
    @IBOutlet weak var problemDescriptionLabel: NSTextField!
    @IBOutlet weak var fixButton: NSButton!
    @IBOutlet weak var problemSeverityIcon: NSImageView!

    var condition: FFXIVCfgCheckCondition?
    var controller: FirstAidController?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    
    @IBAction func pressedFix(_ sender: Any) {
        guard let condition = condition,
        let controller = controller else {
            return
        }

        controller.pressedFix(condition:condition)
        
        if problemDescriptionLabel != nil {
            problemDescriptionLabel!.stringValue = NSLocalizedString("FIRSTAID_CFGCHECK_FIXED", comment: "")
        }
        if problemSeverityIcon != nil {
            switch condition.type {
            case .advisory:
                problemSeverityIcon!.image = NSImage(named: "CfgCheckAdvFixed")
            default:
                problemSeverityIcon!.image = NSImage(named: "CfgCheckProbFixed")
            }
        }
        if fixButton != nil {
            fixButton!.isEnabled = false
        }
    }
}
