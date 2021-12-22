//
//  ViewController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.12.21.
//

import Cocoa

class XIVController: NSViewController {
    
    @IBOutlet private var logger: NSTextView!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        //Setup.downloadDeps()
        Util.launchXL(logger: logger)
    }
    
    @IBAction func play(_ sender: Any) {
        Util.launchXL(logger: logger)
    }
    
    @IBAction func regedit(_ sender: Any) {
        Util.launchWine(args: ["regedit"], logger: logger)
    }
    
    @IBAction func winecfg(_ sender: Any) {
        Util.launchWine(args: ["winecfg"], logger: logger)
    }
    
    @IBAction func explorer(_ sender: Any) {
        Util.launchWine(args: ["explorer"], logger: logger)
    }
    
    @IBAction func cmd(_ sender: Any) {
        Util.launchWine(args: ["cmd"], logger: logger) //fixme
    }
    


}

class XIVWindowController: NSWindowController, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.hide(nil)
        return false
    }
}

extension NSTextView {
    func append(string: String) {
        DispatchQueue.main.async {
            self.textStorage?.append(NSAttributedString(string: string))
            self.scrollToEndOfDocument(nil)
        }
    }
}
