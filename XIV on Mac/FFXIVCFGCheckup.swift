//
//  FFXIVCFGCheckup.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/8/22.
//

import Foundation

let FFXIVCheckupConditions : [FFXIVCfgCheckCondition] = [
    FFXIVCfgCheckCondition(type: .problem, sectionKey: FFXIVCFGSectionLabel.Graphics.rawValue, name: FFXIVCFGOptionKey.Graphics_SSAO.rawValue, proposedValue: "4", comparisonType: .lessthan)
]


public enum FFXIVCfgConditionType {
    case advisory
    case recommendation
    case problem
}

public enum FFXIVCfgConditionComparisonType {
    case equal
    case notequal
    case lessthan
    case greaterthan
}


public struct FFXIVCfgCheckCondition {
    var type : FFXIVCfgConditionType
    var sectionKey : String
    var name : String
    var proposedValue : String
    var comparisonType : FFXIVCfgConditionComparisonType

    public func applyProposedValueToConfig(config:FFXIVCFG){
        if var cfgSection : FFXIVCFGSection = config.sections[sectionKey] {
            cfgSection.contents[name] = proposedValue
        }
    }
    
    public func conditionApplies(config:FFXIVCFG) -> Bool {
        // Trivial so far, but made this a function in case there's more complicated situations in the future
        var applies : Bool = false
        if let cfgSection : FFXIVCFGSection = config.sections[sectionKey] {
            switch comparisonType {
            case .equal:
                applies = cfgSection.contents[name] == proposedValue
            case .notequal:
                applies = cfgSection.contents[name] != proposedValue
            case .lessthan:
                if let currentValue : Int = Int(cfgSection.contents[name]!), let proposedInt : Int = Int(proposedValue){
                    applies = currentValue < proposedInt
                }
            case .greaterthan:
                if let currentValue : Int = Int(cfgSection.contents[name]!), let proposedInt : Int = Int(proposedValue){
                    applies = currentValue > proposedInt
                }
            }
        }
        return applies
    }
    
}
