//
//  CharacterSlotView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/17/24.
//

import SwiftUI

struct CharacterSlotView: View {
	
	var characterData : CharacterDataSlot
	var selected : Bool = false
	let dateFormatter: DateFormatter
	
	init(characterData: CharacterDataSlot, selected : Bool = false) {
		self.characterData = characterData
		self.selected = selected
		dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .long
		dateFormatter.timeStyle = .short
	}
	
    var body: some View {
		VStack {
			if let appearanceData = characterData.appearanceData
			{
				HStack {
					Text(String(characterData.id)).font(.headline)
					Text(characterData.displayName).font(.headline)
					Spacer()
				}
				HStack {
					Text(String(localized:appearanceData.race.localizedName))
					Text(String(localized:appearanceData.tribe.localizedName))
					Text(String(localized:appearanceData.gender.localizedName))
					Spacer()
				}
				HStack {
					Text(characterData.modDate ?? Date(), formatter: dateFormatter).font(.subheadline)
					Spacer()
				}
			}
			else
			{
				HStack {
					Text(String(characterData.id)).font(.headline)
					Text("APPEARANCE_DATA_ERROR_LOADING").font(.headline)
					Spacer()
				}
				HStack {
					Text("")
					Spacer()
				}
			}
		}
		.padding(10)
		.overlay(
			RoundedRectangle(cornerRadius: 10)
				.stroke((selected) ? .blue : .gray , lineWidth: 4)
		)
		.contextMenu {
			if let dataURL = characterData.path
			{
				Button("REVEAL_IN_FINDER") 
				{
					NSWorkspace.shared.activateFileViewerSelecting([dataURL])
				}
			}
		}
    }
}

#Preview {
	let characterData : CharacterDataSlot = Benchmark.findAvailableRetailCharacters().first!
	return CharacterSlotView(characterData: characterData)
}
