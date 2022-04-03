//
//  FirstAidWindowController.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/2/22.
//

import Cocoa

class FirstAidController: NSViewController {

    func checkIfRunning() -> Bool{
        // Since we're deleting or otherwise mucking with files the game may be using or may re-write,
        // we generally want no copies running.
        if (FFXIVApp.running)
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
        if self.checkIfRunning() {
            return
        }
        let alert: NSAlert = NSAlert()
        do {
            try FileManager.default.removeItem(at: Dxvk.userCache)
            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString("DXVK_USER_CACHE_DELETED", comment: "")
            alert.informativeText = NSLocalizedString("DXVK_USER_CACHE_DELETED_INFORMATIVE", comment: "")
        } catch {
            print(error)
            alert.alertStyle = .warning
            alert.messageText = NSLocalizedString("DXVK_USER_CACHE_DELETE_FAILED", comment: "")
            alert.informativeText = NSLocalizedString("DXVK_USER_CACHE_DELETE_FAILED_INFORMATIVE", comment: "")
        }
        alert.addButton(withTitle:NSLocalizedString("OK_BUTTON", comment: ""))
        alert.runModal()
    }
    
    @IBAction func pressedResetConfiguration(_ sender: Any) {
        if self.checkIfRunning() {
            return
        }
        let xomConfigBackupURL = FFXIVApp.configURL.deletingLastPathComponent().appendingPathComponent("FFXIV.cfg.XoMBackup")
        let alert: NSAlert = NSAlert()
        do {
            if (try? xomConfigBackupURL.checkResourceIsReachable()) ?? false {
                // Delete any previous backup we may have made so that the copy will succeed
                try? FileManager.default.removeItem(at: xomConfigBackupURL)
            }
            try FileManager.default.copyItem(at: FFXIVApp.configURL, to: xomConfigBackupURL)
            try FileManager.default.removeItem(at: FFXIVApp.configURL)
            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString("GAME_CONFIG_RESET", comment: "")
            alert.informativeText = NSLocalizedString("GAME_CONFIG_RESET_INFORMATIVE", comment: "")

        } catch {
            print(error)
            alert.alertStyle = .warning
            alert.messageText = NSLocalizedString("GAME_CONFIG_RESET_FAILED", comment: "")
            alert.informativeText = NSLocalizedString("GAME_CONFIG_RESET_FAILED_INFORMATIVE", comment: "")
        }
        alert.addButton(withTitle:NSLocalizedString("OK_BUTTON", comment: ""))
        alert.runModal()
    }
    
}
