//
//  FFXIVCFGEncoder.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/3/22.
//

import Foundation

public class FFXIVCFGEncoder {
    // We are going to try to write a file as close to identical as the game itself does as we possibly can, just in case
    // there's weird bugs in the game's own parser. That means copying every extraneous line and keeping things in the same order.
    
    
    // We could implement an actual Encoder and accept Encodable objects, but it seems overkill; we're
    // not trying to have a general purpose storage format here.
    public static func encode(_ value: FFXIVCFG) throws -> String {
        
        var outputLines : [String] = [""] // CFG file always starts with an empty line
        
        for oneSection in value.sectionOrder {
            // Emit the name of the section
            outputLines.append(String.init(format: "<\(oneSection.name)>"))
            
            for oneTuple in oneSection.contents {
                outputLines.append(String.init(format: "\(oneTuple.key)\t\(oneTuple.value)"))
            }
            
            // Each section ends with an empty line
            outputLines.append("")
        }
        
        return outputLines.joined(separator: "\r\n")
    }

}

public class FFXIVCFGDecoder {
    
    public static func decode(_ value: String) -> FFXIVCFG
    {
        var cfg : FFXIVCFG = FFXIVCFG(sectionMap: [:], sectionOrder: [])
        
        // Get all the lines of the file. This isn't the most efficient method of parsing but
        // since this cfg file isn't particularly large we can keep it simple.
        let lines = value.components(separatedBy: "\r\n")
        var currentSection : FFXIVCFGSection?
        for oneLine in lines {
            if (oneLine.count == 0){
                // Skip empty lines
                continue;
            }
            // Is this line a new section?
            else if let range = oneLine.range(of: #"<(.+)>"#,
                                         options: .regularExpression) {
                // New section
                if currentSection != nil {
                    // Add the now-finished section to the config
                    cfg.sectionOrder.append(currentSection!)
                    cfg.sectionMap[currentSection!.name] = currentSection
                }
                let titleRange = oneLine.index(range.lowerBound, offsetBy: 1)..<oneLine.index(range.upperBound, offsetBy: -1)
                currentSection = FFXIVCFGSection(name:String(oneLine[titleRange]),contents: [])
            }
            else{
                let keyValue = oneLine.components(separatedBy: "\t")
                if (keyValue.count == 2) {
                    let key = keyValue[0]
                    let value = keyValue[1]
                    
                    if (currentSection != nil)
                    {
                        currentSection!.contents.append(ffxivCfgTuple(key,value))
                    }
                    else
                    {
                        print("Found a value tuple before a section header!")
                    }

                }
            }
        }
        if currentSection != nil {
            // Add the now-finished section to the config
            cfg.sectionOrder.append(currentSection!)
            cfg.sectionMap[currentSection!.name] = currentSection
        }

        return cfg
    }
    
    
}

typealias ffxivCfgTuple = (key: String, value: String)

public struct FFXIVCFG {
    // These contain the same information, but the map is much more useful for reading/using, while the "order"
    // is neccesary for us to ultimately write this back to disk in the same order we got it.
    var sectionMap : [String:FFXIVCFGSection]
    var sectionOrder : [FFXIVCFGSection]
    
}

public struct FFXIVCFGSection {
    var name : String
    var contents : [ffxivCfgTuple]
}
