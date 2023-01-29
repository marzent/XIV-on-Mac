//
//  FirstAidWindowController.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/2/22.
//

import Cocoa

class FirstAidController: ObservableObject {
    @Published var cfgCheckOverallResult: FFXIVCfgConditionType = .noissue

    @Published var cfgProblems: [FFXIVCfgCheckCondition] = .init()
    
    var ffxivCfg: FFXIVCFG?

    func willAppear() {
        if ffxivCfg == nil {
            // This will be nil if we're being loaded because the user voluntarily opened us. If, instead, we're opened because
            // there's a "severe" issue preventing login, we don't want to load ALL issues, leave the list alone to focus on the major problem(s)
            pressedCfgCheckup(self)
        }
    }

    func updateWorstIssue() {
        let worstIssueType: FFXIVCfgConditionType = cfgProblems.filter { $0.fixed == false }.max(by: { $0.type.rawValue < $1.type.rawValue })?.type ?? FFXIVCfgConditionType.noissue
        cfgCheckOverallResult = worstIssueType
    }
    
    func checkIfRunning() -> Bool {
        // Since we're deleting or otherwise mucking with files the game may be using or may re-write,
        // we generally want no copies running.
        if Wine.running(processName: "ffxiv_dx11.exe") {
            let alert: NSAlert = .init()
            alert.alertStyle = .warning
            alert.messageText = NSLocalizedString("FIRSTAID_GAME_RUNNING", comment: "")
            alert.informativeText = NSLocalizedString("FIRSTAID_GAME_RUNNING", comment: "")
            alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
            alert.runModal()
            return true
        }
        return false
    }
    
    func pressedDeleteUserCache(_ sender: Any) {
        if checkIfRunning() {
            return
        }
        let alert = NSAlert()
        do {
            try FileManager.default.removeItem(at: Dxvk.userCacheURL)
            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString("DXVK_USER_CACHE_DELETED", comment: "")
            alert.informativeText = NSLocalizedString("DXVK_USER_CACHE_DELETED_INFORMATIVE", comment: "")
        }
        catch {
            Log.error(error.localizedDescription)
            alert.alertStyle = .warning
            alert.messageText = NSLocalizedString("DXVK_USER_CACHE_DELETE_FAILED", comment: "")
            alert.informativeText = NSLocalizedString("DXVK_USER_CACHE_DELETE_FAILED_INFORMATIVE", comment: "")
        }
        alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
        alert.runModal()
    }
    
    func pressedResetConfiguration(_ sender: Any) {
        if checkIfRunning() {
            return
        }
        let xomConfigBackupURL = FFXIVApp.configURL.deletingLastPathComponent().appendingPathComponent("FFXIV.cfg.XoMBackup")
        let alert = NSAlert()
        do {
            if (try? xomConfigBackupURL.checkResourceIsReachable()) ?? false {
                // Delete any previous backup we may have made so that the copy will succeed
                try? FileManager.default.removeItem(at: xomConfigBackupURL)
            }
            try FileManager.default.copyItem(at: FFXIVApp.configURL, to: xomConfigBackupURL)
            try FileManager.default.removeItem(at: FFXIVApp.configURL)
            let defaultCfgURL = Bundle.main.url(forResource: "FFXIV-MacDefault", withExtension: "cfg")!
            try FileManager.default.copyItem(at: defaultCfgURL, to: FFXIVApp.configURL)

            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString("GAME_CONFIG_RESET", comment: "")
            alert.informativeText = NSLocalizedString("GAME_CONFIG_RESET_INFORMATIVE", comment: "")
        }
        catch {
            Log.error(error.localizedDescription)
            alert.alertStyle = .warning
            alert.messageText = NSLocalizedString("GAME_CONFIG_RESET_FAILED", comment: "")
            alert.informativeText = NSLocalizedString("GAME_CONFIG_RESET_FAILED_INFORMATIVE", comment: "")
        }
        alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
        alert.runModal()
    }
    
    func pressedCfgCheckup(_ sender: Any) {
        // Force a re-read of the cfg file when the button is pressed
        ffxivCfg = nil
        let conditions: [FFXIVCfgCheckCondition] = cfgCheckConditions().filter { $0.type.rawValue >= FFXIVCfgConditionType.recommendation.rawValue }
        _ = cfgCheckFilteredProblems(conditions: conditions)
    }
    
    func getCurrentCfg() -> FFXIVCFG {
        if ffxivCfg == nil {
            if let configFileContents = Util.loadCfgFile() {
                ffxivCfg = FFXIVCFGDecoder.decode(configFileContents)
            }
            else {
                return FFXIVCFG()
            }
        }
        return ffxivCfg!
    }
    
    func writeCurrentCfg() {
        guard let ffxivCfg = ffxivCfg else {
            return
        }

        do {
            let outputCfgString = try FFXIVCFGEncoder.encode(ffxivCfg)
            try outputCfgString.write(to: FFXIVApp.configURL, atomically: true, encoding: .utf8)
        }
        catch {
            Log.error(error.localizedDescription)
        }
    }
    
    func cfgCheckFilteredProblems(conditions: [FFXIVCfgCheckCondition]) -> Bool {
        let config = getCurrentCfg()
        var foundConditions: [FFXIVCfgCheckCondition] = []
        
        for oneCondition in conditions {
            if oneCondition.conditionApplies(config: config) {
                foundConditions.append(oneCondition)
            }
        }
        
        cfgProblems = foundConditions
        updateWorstIssue()
        return foundConditions.count > 0
    }
    
    func cfgCheckConditions() -> [FFXIVCfgCheckCondition] {
        var allConditions: [FFXIVCfgCheckCondition] = FFXIVCheckupConditions
        if Util.getXOMRuntimeEnvironment() != .x64Native {
            allConditions = allConditions + FFXIVCheckupConditions_AS
        }
        else {
            allConditions = allConditions + FFXIVCheckupConditions_X64
        }
        return allConditions
    }
    
    func cfgCheckSevereProblems() -> Bool {
        let conditions: [FFXIVCfgCheckCondition] = cfgCheckConditions().filter { $0.type == .problem }
        return cfgCheckFilteredProblems(conditions: conditions)
    }
    
    func pressedFix(condition: FFXIVCfgCheckCondition) {
        var config = getCurrentCfg()
        condition.applyProposedValueToConfig(config: &config)
        writeCurrentCfg()
        updateWorstIssue()
    }
    
    private static let retinaWorkaroundAskedSettingKey = "AskedRetinaWorkaround"
    
    func applyRetinaWorkaround() {
        if Wine.retina {
            let config = getCurrentCfg()
            if let section = config.sections[FFXIVCFGSectionLabel.Display.rawValue] {
                if let screenMode = section.contents[FFXIVCFGOptionKey.Display_ScreenMode.rawValue]
                {
                    if screenMode != FFXIVCFGDisplay_ScreenMode.Windowed.rawValue {
                        if !Wine.retinaStartupBugWorkaround &&
                            !Util.getSetting(settingKey: FirstAidController.retinaWorkaroundAskedSettingKey, defaultValue: false)
                        {
                            // If the bug workaround is off, *but* we've never asked to enable it, ask now
                            let alert: NSAlert = .init()
                            alert.messageText = NSLocalizedString("RETINA_WORKAROUND_OPTIN", comment: "")
                            alert.informativeText = NSLocalizedString("RETINA_WORKAROUND_OPTIN_INFORMATIVE", comment: "")
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: NSLocalizedString("RETINA_WORKAROUND_OPTIN_ENABLE", comment: ""))
                            alert.addButton(withTitle: NSLocalizedString("RETINA_WORKAROUND_OPTIN_DISABLE", comment: ""))
                            let result = alert.runModal()
                            if result == .alertFirstButtonReturn {
                                Wine.retinaStartupBugWorkaround = true
                            }
                            
                            // Regardless of response, note that we asked so we don't next time.
                            UserDefaults.standard.set(true, forKey: FirstAidController.retinaWorkaroundAskedSettingKey)
                        }
                        
                        // Check again now in case they enabled it above.
                        if Wine.retinaStartupBugWorkaround {
                            // Simply set the ScreenMode to windowed
                            section.contents[FFXIVCFGOptionKey.Display_ScreenMode.rawValue] = FFXIVCFGDisplay_ScreenMode.Windowed.rawValue
                            writeCurrentCfg()
                        }
                    }
                }
            }
        }
    }
}
