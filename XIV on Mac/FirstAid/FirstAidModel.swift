//
//  FirstAidModel.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/2/22.
//

import Cocoa

class FirstAidModel: ObservableObject {
    @Published var cfgCheckOverallResult: FFXIVCfgConditionType = .noissue
    @Published var cfgProblems: [FFXIVCfgCheckCondition] = .init()

    private var ffxivCfg: FFXIVCFG?

    init() {
        reloadCfg()
    }

    func updateWorstIssue() {
        let worstIssueType: FFXIVCfgConditionType =
            cfgProblems.filter { $0.fixed == false }.max(by: {
                $0.type.rawValue < $1.type.rawValue
            })?.type ?? FFXIVCfgConditionType.noissue
        cfgCheckOverallResult = worstIssueType
    }

    func reloadCfg() {
        ffxivCfg = nil
        let conditions: [FFXIVCfgCheckCondition] = cfgCheckConditions().filter {
            $0.type.rawValue >= FFXIVCfgConditionType.recommendation.rawValue
        }
        _ = cfgCheckFilteredProblems(conditions: conditions)
    }

    func getCurrentCfg() -> FFXIVCFG {
        if ffxivCfg == nil {
            if let configFileContents = FFXIVApp.loadCfgFile() {
                ffxivCfg = FFXIVCFGDecoder.decode(configFileContents)
            } else {
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
            try outputCfgString.write(
                to: FFXIVApp.configURL, atomically: true, encoding: .utf8)
        } catch {
            Log.error(error.localizedDescription)
        }
    }

    func cfgCheckFilteredProblems(conditions: [FFXIVCfgCheckCondition]) -> Bool
    {
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
        } else {
            allConditions = allConditions + FFXIVCheckupConditions_X64
        }
        return allConditions
    }

    func cfgCheckSevereProblems() -> Bool {
        let conditions: [FFXIVCfgCheckCondition] = cfgCheckConditions().filter {
            $0.type == .problem
        }
        return cfgCheckFilteredProblems(conditions: conditions)
    }

    func fix(condition: FFXIVCfgCheckCondition) {
        var config = getCurrentCfg()
        condition.applyProposedValueToConfig(config: &config)
        writeCurrentCfg()
        updateWorstIssue()
    }
}
