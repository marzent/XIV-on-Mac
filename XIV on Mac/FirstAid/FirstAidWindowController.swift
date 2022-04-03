//
//  FirstAidWindowController.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/2/22.
//

import Cocoa

class FirstAidWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    
    }

    func checkIfRunning() -> Bool{
        // Since we're deleting or otherwise mucking with files the game may be using or may re-write,
        // we generally want no copies running.
        if (FFXIVApp.instances > 0)
        {
            let alert: NSAlert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = NSLocalizedString("FIRSTAID_GAME_RUNNING", comment: "")
            alert.informativeText = NSLocalizedString("FIRSTAID_GAME_RUNNING", comment: "")
            alert.addButton(withTitle:NSLocalizedString("OK_BUTTON", comment: ""))
            alert.runModal()

            return true
        }
        return false
    }
    
    @IBAction func pressedDeleteUserCache(_ sender: Any) {
        if self.checkIfRunning(){
            return
        }
        
        let userCacheLocation = Wine.prefix.appendingPathComponent("drive_c/" + "ffxiv_dx11.dxvk-cache")
        let alert: NSAlert = NSAlert()
        do{
            try FileManager.default.removeItem(at: userCacheLocation)
            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString("DXVK_USER_CACHE_DELETED", comment: "")
            alert.informativeText = NSLocalizedString("DXVK_USER_CACHE_DELETED_INFORMATIVE", comment: "")
        }catch{
            print(error)
            alert.alertStyle = .warning
            alert.messageText = NSLocalizedString("DXVK_USER_CACHE_DELETE_FAILED", comment: "")
            alert.informativeText = NSLocalizedString("DXVK_USER_CACHE_DELETE_FAILED_INFORMATIVE", comment: "")
        }
        alert.addButton(withTitle:NSLocalizedString("OK_BUTTON", comment: ""))
        alert.runModal()
    }
    
    @IBAction func pressedResetConfiguration(_ sender: Any) {
        if self.checkIfRunning(){
            return
        }
        
        let userHome = FileManager.default.homeDirectoryForCurrentUser
        // Todo: Move these paths to some utility class when cfg file parsing is implemented
        let gameConfigFolder = userHome.appendingPathComponent("/Documents/My Games/FINAL FANTASY XIV - A Realm Reborn/")
        let mainConfigFile = "FFXIV.cfg"
        let xomMainConfigBackupFile = "FFXIV.cfg.XoMBackup"
        let alert: NSAlert = NSAlert()

        do {
            let xomBackupPath = gameConfigFolder.appendingPathComponent(xomMainConfigBackupFile)
            let mainConfigPath = gameConfigFolder.appendingPathComponent(mainConfigFile)
            do {
                if try xomBackupPath.checkResourceIsReachable(){
                    // Delete any previous backup we may have made so that the copy will succeed
                    try FileManager.default.removeItem(at: xomBackupPath)
                }
            }
            catch{}
            
            try FileManager.default.copyItem(at:mainConfigPath , to: xomBackupPath)
            try FileManager.default.removeItem(at: mainConfigPath)
            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString("GAME_CONFIG_RESET", comment: "")
            alert.informativeText = NSLocalizedString("GAME_CONFIG_RESET_INFORMATIVE", comment: "")

        }catch{
            print(error)
            alert.alertStyle = .warning
            alert.messageText = NSLocalizedString("GAME_CONFIG_RESET_FAILED", comment: "")
            alert.informativeText = NSLocalizedString("GAME_CONFIG_RESET_FAILED_INFORMATIVE", comment: "")
        }
        alert.addButton(withTitle:NSLocalizedString("OK_BUTTON", comment: ""))
        alert.runModal()

    }
    
}
