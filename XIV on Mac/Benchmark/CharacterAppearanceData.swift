//
//  CharacterAppearanceData.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/17/24.
//

import Foundation
import SwiftUI

struct CharacterAppearanceDataRaw
{
	// We do NOT directly declare these as their enums if available, because raw values that don't
	// fit within the enum will cause runtime crashes in the event of a corrupt file.
	// Fields appear in Byte order as they do in the raw file. Do not re-order.
	// Field  - Byte #
	var race : UInt8 // 1
	var gender : UInt8 // 2
	var age : UInt8 // 3
	var height : UInt8 // 4
	var tribe : UInt8 // 5
	var headType : UInt8 // 6
	var hairType : UInt8 // 7
	var highlightsEnabled : UInt8 // 8
	var skintone : UInt8 // 9
	var rightEyeColor : UInt8 // 10
	var hairTone : UInt8 // 11
	var highlights : UInt8 // 12
	var facialFeatures : UInt8 // 13
	var limbalEyes : UInt8 // 14
	var eyebrows : UInt8 // 15
	var leftEyeColor : UInt8 // 16
	var eyeType : UInt8 // 17
	var noseType : UInt8 // 18
	var jawType : UInt8 // 19
	var mouthType : UInt8 // 20
	var lipToneOrFurPattern : UInt8 // 21
	var earMuscleTailSize : UInt8 // 22
	var tailEarsType : UInt8 // 23
	var bustSize : UInt8; // 24
	var facePaintType : UInt8 // 25
	var facePaintColor : UInt8 // 26
}

struct CharacterAppearanceData
{
	public enum Genders : UInt8
	{
		case masculine = 0
		case feminine = 1
		case unknown = 255
		
		var localizedName: String.LocalizationValue { String.LocalizationValue(stringLiteral:String(format:"APPEARANCE_GENDER_%d",rawValue)) }
	}
	
	public var gender: Genders
	{
		return Genders(rawValue: rawData.gender) ?? Genders.unknown
	}
	
	public enum Ages : UInt8
	{
		case unknown = 0
		case normal = 1
		case old = 3
		case young = 4
	}

	
	public enum Races : UInt8
	{
		case unknown = 0
		case hyur = 1
		case elezen = 2
		case lalafel = 3
		case miqote = 4
		case roegadyn = 5
		case aura = 6
		case hrothgar = 7
		case viera = 8
		
		var localizedName: String.LocalizationValue { String.LocalizationValue(stringLiteral:String(format:"APPEARANCE_RACE_%d",rawValue)) }
	}

	public var race : Races
	{
		return Races(rawValue: rawData.race) ?? Races.unknown
	}
	
	public enum Tribes : UInt8
	{
		case unknown = 0
		case midlander = 1
		case highlander = 2
		case wildwood = 3
		case duskwight = 4
		case plainsfolk = 5
		case dunesfolk = 6
		case seekerOfTheSun = 7
		case keeperOfTheMoon = 8
		case seaWolf = 9
		case hellsguard = 10
		case raen = 11
		case xaela = 12
		case helions = 13
		case theLost = 14
		case rava = 15
		case veena = 16
		
		var localizedName: String.LocalizationValue { String.LocalizationValue(stringLiteral:(String(format:"APPEARANCE_TRIBE_%d",rawValue))) }

	}
	
	public var tribe : Tribes
	{
		return Tribes(rawValue: rawData.tribe) ?? Tribes.unknown
	}
	
	private let rawData : CharacterAppearanceDataRaw

	init(rawData:CharacterAppearanceDataRaw)
	{
		self.rawData = rawData
	}
}

struct CharacterDataSlot : Identifiable, Comparable
{
	var id : Int
	var name : String
	var path : URL?
	var appearanceData : CharacterAppearanceData?
	var modDate : Date?
	
	static func ==(lhs: CharacterDataSlot, rhs: CharacterDataSlot) -> Bool {
		return lhs.id == rhs.id
	}
	
	static func <(lhs: CharacterDataSlot, rhs: CharacterDataSlot) -> Bool {
		return lhs.id < rhs.id
	}

	
	init(id: Int, dataURL: URL?)
	{
		self.id = id
		name = ""
		path = dataURL
		if path != nil
		{
			loadData()
		}
	}
	
	var displayName : String
	{
		return (name.count == 0) ? NSLocalizedString("BENCHMARK_CHARACTER_UNNAMED",comment: "" ) : name
	}

	var longDisplayName : String
	{
		guard let appearanceData = appearanceData else
		{
			return self.displayName
		}
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .short
		dateFormatter.timeStyle = .short
		let modDate = modDate ?? Date()

		return String(format: "%@ – %@ %@ %@ – %@",
					  self.displayName,
					  String(localized: appearanceData.race.localizedName),
					  String(localized: appearanceData.tribe.localizedName),
					  String(localized: appearanceData.gender.localizedName),
					  dateFormatter.string(from: modDate))
	}

	private mutating func loadData()
	{
		guard let path = path else {return}
		
		modDate = try? path.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
		
		if let fileHandle: FileHandle = try? FileHandle(forReadingFrom: path)
		{
			try? fileHandle.seek(toOffset: 0x10) // Start of appearance section
			if let rawCharacterData: Data = try? fileHandle.read(upToCount: MemoryLayout<CharacterAppearanceDataRaw>.size)
			{
				// Get the attributes
				let byteArray: [UInt8] = rawCharacterData.map { $0 }
				let rawCharacter: CharacterAppearanceDataRaw = byteArray.withUnsafeBufferPointer {
					($0.baseAddress!.withMemoryRebound(to: CharacterAppearanceDataRaw.self, capacity: 1) { $0 })
					}.pointee
				appearanceData = CharacterAppearanceData(rawData: rawCharacter)
			
				// Get the name/comment, if any
				try? fileHandle.seek(toOffset: 0x30) // User name starts 48 bytes in
				if let characterData: Data = try? fileHandle.read(upToCount:212) // Files are only 212 bytes total.
				{
					var characterName: String = ""
					for byteNum in 0...characterData.count {
						let oneByte : UInt8 = characterData[byteNum]
						if oneByte == 0 { break }
						characterName.append(String(UnicodeScalar(oneByte)))
					}
					// Names in these files are optional so it might be blank.
					name = characterName
				}
			}
		}
	}
}
