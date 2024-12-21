//
//  FFXIVCFGCheckup.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/8/22.
//

import Foundation

let FFXIVCheckupConditions: [FFXIVCfgCheckCondition] = []

// Conditions which only apply to Apple Silicon
let FFXIVCheckupConditions_AS: [FFXIVCfgCheckCondition] = [
    FFXIVCfgCheckCondition(
        title: NSLocalizedString(
            "FIRSTAID_CFGCHECK_TESSELATION_TITLE", comment: ""),
        explanation: NSLocalizedString(
            "FIRSTAID_CFGCHECK_TESSELATION_EXP", comment: ""),
        type: .advisory, sectionKey: FFXIVCFGSectionLabel.Graphics.rawValue,
        name: FFXIVCFGOptionKey.Graphics_Tesselation.rawValue,
        comparisonValue: "3", proposedValue: "2", comparisonType: .lessthan)
]

// Conditions which only apply to Intel
let FFXIVCheckupConditions_X64: [FFXIVCfgCheckCondition] = []

public enum FFXIVCfgConditionType: Int {
    /// This condition  is not a problem, but we want to tell them about it anyway for some reason.
    case noissue
    /// The user may get some benefit by changing this. Usually used for graphics settings to either improve performance or appearance.
    case recommendation
    /// The user might be experiencing a detrimental effect from this setting, such as heavily degraded performance or glitches.
    case advisory
    /// This setting is just broken in some way and the user shouldn't be permitted to start the game with it set because it WILL cause a problem. Use very sparingly.
    case problem
}

public enum FFXIVCfgConditionComparisonType {
    case equal
    case notequal
    case lessthan
    case greaterthan
}

public class FFXIVCfgCheckCondition: Identifiable {
    public var id: String { name }

    var title: String
    var explanation: String
    var type: FFXIVCfgConditionType
    var sectionKey: String
    var name: String
    var comparisonValue: String
    var proposedValue: String
    var comparisonType: FFXIVCfgConditionComparisonType
    var fixed: Bool = false

    init(
        title: String, explanation: String, type: FFXIVCfgConditionType,
        sectionKey: String, name: String, comparisonValue: String,
        proposedValue: String, comparisonType: FFXIVCfgConditionComparisonType
    ) {
        self.title = title
        self.explanation = explanation
        self.type = type
        self.sectionKey = sectionKey
        self.name = name
        self.comparisonValue = comparisonValue
        self.proposedValue = proposedValue
        self.comparisonType = comparisonType
    }

    public func applyProposedValueToConfig(config: inout FFXIVCFG) {
        if let cfgSection: FFXIVCFGSection = config.sections[sectionKey] {
            cfgSection.contents[name] = proposedValue
            fixed = true
        }
    }

    public func conditionApplies(config: FFXIVCFG) -> Bool {
        // Trivial so far, but made this a function in case there's more complicated situations in the future
        var applies = false
        if let cfgSection: FFXIVCFGSection = config.sections[sectionKey] {
            switch comparisonType {
            case .equal:
                applies = cfgSection.contents[name] == comparisonValue
            case .notequal:
                applies = cfgSection.contents[name] != comparisonValue
            case .lessthan:
                if let currentValue = Int(cfgSection.contents[name]!),
                    let comparisonInt = Int(comparisonValue)
                {
                    applies = comparisonInt <= currentValue
                }
            case .greaterthan:
                if let currentValue = Int(cfgSection.contents[name]!),
                    let comparisonInt = Int(comparisonValue)
                {
                    applies = comparisonInt > currentValue
                }
            }
        }
        return applies
    }
}
