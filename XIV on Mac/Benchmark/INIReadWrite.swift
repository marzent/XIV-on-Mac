//
//  INIReadWrite.swift
//  XIV on Mac
//
//  Created by Chris Backas on 2/20/23.
//

import Foundation

public class INIFileEncoder {
    public static func encode(_ value: INIFile) throws -> String {

        var outputLines: [String] = []

        for oneSectionKey in value.sectionOrder {
            if let oneSection: INIFileSection = value.sections[oneSectionKey] {
                // Emit the name of the section
                outputLines.append(String.init(format: "[\(oneSection.name)]"))

                for oneTupleKey in oneSection.contentOrder {
                    if let oneValue: String = oneSection.contents[oneTupleKey] {
                        outputLines.append(
                            String.init(format: "\(oneTupleKey)=\(oneValue)"))
                    }
                }
            }
        }

        return outputLines.joined(separator: "\r\n")
    }

}

public class INIFileDecoder {

    public static func decode(_ value: String) -> INIFile {
        let iniFile: INIFile = INIFile()
        // Get all the lines of the file. This isn't the most efficient method of parsing but
        // since this cfg file isn't particularly large we can keep it simple.
        let lines = value.components(separatedBy: "\r\n")
        var currentSection: INIFileSection?
        for oneLine in lines {
            if oneLine.count == 0 {
                // Skip empty lines
                continue
            }
            // Is this line a new section?
            else if let range = oneLine.range(
                of: #"\[(.+)\]"#, options: .regularExpression)
            {
                // New section
                if currentSection != nil {
                    // Add the now-finished section to the config
                    iniFile.addSection(newSection: currentSection!)
                }
                let titleRange =
                    oneLine.index(
                        range.lowerBound, offsetBy: 1)..<oneLine.index(
                        range.upperBound, offsetBy: -1)
                currentSection = INIFileSection(
                    name: String(oneLine[titleRange]))
            } else {
                let keyValue = oneLine.components(separatedBy: "=")
                if keyValue.count == 2 {
                    let key = keyValue[0]
                    let value = keyValue[1]

                    if currentSection != nil {
                        currentSection?.setValue(key: key, value: value)
                    } else {
                        Log.warning(
                            "Found a value tuple before a section header!")
                    }
                }
            }
        }
        if currentSection != nil {
            // Add the now-finished section to the config
            iniFile.sectionOrder.append(currentSection!.name)
            iniFile.sections[currentSection!.name] = currentSection
        }
        return iniFile
    }

}

public class INIFile {
    var sections: [String: INIFileSection] = [:]
    // Keys to 'sections' in the order they originally appeared in the file
    var sectionOrder: [String] = []
    public func addSection(newSection: INIFileSection) {
        sectionOrder.append(newSection.name)
        sections[newSection.name] = newSection
    }
}

public class INIFileSection {
    var name: String
    var contents: [String: String] = [:]
    // Keys to 'contents' in the order they originally appeared in the file
    var contentOrder: [String] = []

    public func setValue(key: String, value: String) {
        if contents[key] == nil {
            contentOrder.append(key)
        }
        contents[key] = value
    }

    init(name: String) {
        self.name = name
    }
}
