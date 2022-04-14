//
//  FirstAidWindowController.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/2/22.
//

import Cocoa

class FirstAidController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var cfgCheckTable: NSTableView?
    @IBOutlet weak var cfgCheckResultImage: NSImageView?
    @IBOutlet weak var cfgCheckResultLabel: NSTextField?

    var cfgProblems: [FFXIVCfgCheckCondition] = [] {
        didSet {
            guard let cfgCheckTable = self.cfgCheckTable else {
                return
            }
            cfgCheckTable.reloadData()
            guard let cfgCheckResultImage = self.cfgCheckResultImage,
                  let cfgCheckResultLabel = self.cfgCheckResultLabel else {
                return
            }
            let worstIssueType: FFXIVCfgConditionType = cfgProblems.max(by:{$0.type.rawValue < $1.type.rawValue})?.type ?? FFXIVCfgConditionType.noissue
            var resultImage: NSImage?
            var resultText: String
            switch worstIssueType {
            case .noissue:
                resultImage = NSImage(named: "CfgCheckGood.tiff")
                resultText = NSLocalizedString("FIRSTAID_CFGCHECK_GOOD_RESULT", comment: "")
            case .advisory:
                resultImage = NSImage(named: "CfgCheckGood.tiff")
                resultText = NSLocalizedString("FIRSTAID_CFGCHECK_ADVISORY_RESULT", comment: "")
            case .recommendation:
                resultImage = NSImage(named: "CfgCheckGood.tiff")
                resultText = NSLocalizedString("FIRSTAID_CFGCHECK_RECOMMENDATION_RESULT", comment: "")
            case .problem:
                resultImage = NSImage(named: "CfgCheckProblems.tiff")
                resultText = NSLocalizedString("FIRSTAID_CFGCHECK_PROBLEM_RESULT", comment: "")
            }
            
            cfgCheckResultImage.image = resultImage
            cfgCheckResultLabel.stringValue = resultText
        }
    }
    
    var ffxivCfg: FFXIVCFG?

    override func viewWillAppear() {
        super.viewWillAppear()
        if ffxivCfg == nil {
            // This will be nil if we're being loaded because the user voluntarily opened us. If, instead, we're opened because
            // there's a "severe" issue preventing login, we don't want to load ALL issues, leave the list alone to focus on the major problem(s)
            pressedCfgCheckup(self)
        }
    }

    
    func checkIfRunning() -> Bool {
        // Since we're deleting or otherwise mucking with files the game may be using or may re-write,
        // we generally want no copies running.
        if (FFXIVApp.running) {
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
            try FileManager.default.removeItem(at: Dxvk.userCacheURL)
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
    
    @IBAction func pressedCfgCheckup(_ sender: Any) {
        // Force a re-read of the cfg file when the button is pressed
        ffxivCfg = nil
        let conditions : [FFXIVCfgCheckCondition] = cfgCheckConditions().filter {$0.type.rawValue >= FFXIVCfgConditionType.recommendation.rawValue}
        _ = cfgCheckFilteredProblems(conditions:conditions)
    }
    
    // Table View support
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return cfgProblems.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let firstAidCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FirstAidResult"), owner: self) as? FirstAidTableCellView else {
            return nil
        }
        let problem: FFXIVCfgCheckCondition = cfgProblems[row]
        
        firstAidCell.condition = problem
        firstAidCell.controller = self
        firstAidCell.problemDescriptionLabel.stringValue = problem.explanation
        firstAidCell.problemTitleLabel.stringValue = problem.title
        firstAidCell.fixButton.isEnabled = true
        switch problem.type {
        case .advisory:
            firstAidCell.problemSeverityIcon.image = NSImage(named: "CfgCheckAdvFailed.tiff")
        case .problem:
            firstAidCell.problemSeverityIcon.image = NSImage(named: "CfgCheckProbFailed.tiff")
        default:
            firstAidCell.problemSeverityIcon.image = NSImage(named: "CfgCheckGood.tiff")
        }
            
        return firstAidCell
    }
    
    func getCurrentCfg() -> FFXIVCFG {
        if (ffxivCfg == nil) {
            do {
                let configFileContents = try String(contentsOf:FFXIVApp.configURL)
                ffxivCfg = FFXIVCFGDecoder.decode(configFileContents)
            }
            catch {
                print(error)
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
            print(error)
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
        
        return foundConditions.count > 0
    }
    
    func cfgCheckConditions() -> [FFXIVCfgCheckCondition] {
        var allConditions: [FFXIVCfgCheckCondition] = FFXIVCheckupConditions
        #if arch(arm64)
        allConditions = allConditions + FFXIVCheckupConditions_AS
        #else
        allConditions = allConditions + FFXIVCheckupConditions_X64
        #endif
        return allConditions
    }
    
    func cfgCheckSevereProblems() -> Bool {
        let conditions: [FFXIVCfgCheckCondition] = cfgCheckConditions().filter({$0.type == .problem})
        return cfgCheckFilteredProblems(conditions:conditions)
    }
    
    func pressedFix(condition: FFXIVCfgCheckCondition) {
        var config = getCurrentCfg()
        condition.applyProposedValueToConfig(config: &config)
        writeCurrentCfg()
    }
}
