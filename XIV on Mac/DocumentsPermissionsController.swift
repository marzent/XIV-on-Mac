//
//  DocumentsPermissionsController.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/22/22.
//

import Cocoa

class DocumentsPermissionsController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBOutlet weak var explanatoryTextField: NSTextField!
    
    @IBAction func pressedOpenSecPrefpane(_ sender: Any) {
        guard let prefpaneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_DocumentsFolder") else
        {
            print("Unable to form prefpane URL")
            return
        }
        NSWorkspace.shared.open(prefpaneURL)
    }
    
    @IBAction func pressedRecheck(_ sender: Any) {
        if Util.documentsFolderWritable() {
            self.view.window?.sheetParent?.contentViewController?.dismiss(self)
        }
        else
        {
            self.explanatoryTextField.stringValue = NSLocalizedString("DOCUMENTS_PERM_STILL_BAD", comment: "")
            self.explanatoryTextField.textColor = .systemRed
        }

    }
}
