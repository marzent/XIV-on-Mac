//
//  CharacterDataImportView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/17/24.
//

import SwiftUI

struct CharacterSlotParentView: View {
    var oneCharacter: CharacterDataSlot
    public let selected: Bool

    var body: some View {
        CharacterSlotView(characterData: oneCharacter, selected: selected)
            .listRowBackground(Color(nsColor: .windowBackgroundColor))
    }
}

struct CharacterDataListView: View {
    @Binding public var characterData: [CharacterDataSlot]
    @Binding public var selection: Int?

    var body: some View {
        List(selection: $selection) {
            ForEach(characterData) { oneCharacter in
                CharacterSlotView(
                    characterData: oneCharacter,
                    selected: (selection == oneCharacter.id))
            }
        }
        .listStyle(.bordered)
        .id(UUID())  // Dumb hack, but this causes SwiftUI to actually re-render the CharacterSlotView on change for... reasons.
        //.scrollContentBackground(.hidden)
    }
}

class CharacterListState: ObservableObject {
    @Published var targetCharacters: [CharacterDataSlot] = [CharacterDataSlot]()
    @Published var sourceCharacters: [CharacterDataSlot] = [CharacterDataSlot]()

    func pad(cdsArray: [CharacterDataSlot], toSize: Int) -> [CharacterDataSlot]
    {
        var ReturnMe: [CharacterDataSlot] = [CharacterDataSlot]()
        let highestSlot: Int = cdsArray.max()?.id ?? 0
        let listSize = max(toSize, highestSlot)
        for slot in 1...listSize {
            if let existingData = cdsArray.filter({ $0.id == slot }).first {
                ReturnMe.append(existingData)
            } else {
                ReturnMe.append(CharacterDataSlot(id: slot, dataURL: nil))
            }
        }
        return ReturnMe
    }

    func loadSourceFromDiscordTeam() {
        sourceCharacters = pad(
            cdsArray: Benchmark.findAvailableDiscordTeamCharacters().sorted(
                by: { $0.id < $1.id }),
            toSize: 0)
    }

    func loadTargetFromDemo() {
        targetCharacters = pad(
            cdsArray: Benchmark.findAvailableDemoCharacters().sorted(by: {
                $0.id < $1.id
            }),
            toSize: 40)
    }

    func loadSourceFromRetail() {
        sourceCharacters = pad(
            cdsArray: Benchmark.findAvailableRetailCharacters().sorted(by: {
                $0.id < $1.id
            }),
            toSize: 0)
    }
}

struct CharacterDataImportView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var characterListState = CharacterListState()

    @State private var benchmarkCharacterSelection: Int?
    @State private var importableCharacterSelection: Int?
    @State private var discordCrew: Bool = false

    func loadDiscordCrew() {
        if !discordCrew {
            discordCrew = true
            characterListState.loadSourceFromDiscordTeam()
            importableCharacterSelection = nil
        }
    }

    var body: some View {
        let benchmarkVersion: BenchmarkVersion = Benchmark.benchmarkVersion()
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                KwehView(chocoWalkUnits: 15, chocoFence: 500)
                    .onTapGesture {
                        loadDiscordCrew()
                    }
                VStack {
                    HStack {
                        VStack {
                            Text("BENCHMARK_SLOTS_LIST_LABEL").font(.title)
                            CharacterDataListView(
                                characterData: $characterListState
                                    .targetCharacters,
                                selection: $benchmarkCharacterSelection)
                            HStack {
                                Button(
                                    "BENCHMARK_SLOT_DELETE_BUTTON",
                                    role: .destructive
                                ) {
                                    let alert: NSAlert = .init()
                                    alert.messageText = NSLocalizedString(
                                        "BENCHMARK_CONFIRM_SLOT_DELETE",
                                        comment: "")
                                    alert.informativeText = NSLocalizedString(
                                        "BENCHMARK_CONFIRM_SLOT_DELETE_INFORMATIVE",
                                        comment: "")
                                    alert.alertStyle = .warning
                                    alert.addButton(
                                        withTitle: NSLocalizedString(
                                            "BUTTON_DELETE", comment: ""))
                                    alert.addButton(
                                        withTitle: NSLocalizedString(
                                            "BUTTON_CANCEL", comment: ""))
                                    let result = alert.runModal()
                                    if result == .alertFirstButtonReturn {
                                        if let deleteCharacter =
                                            characterListState.targetCharacters
                                            .filter({
                                                $0.id
                                                    == benchmarkCharacterSelection
                                            }).first
                                        {
                                            if let path = deleteCharacter.path {
                                                try? FileManager.default
                                                    .removeItem(at: path)
                                            }
                                        }
                                        characterListState.loadTargetFromDemo()
                                        benchmarkCharacterSelection = nil
                                    }

                                }
                                .disabled(benchmarkCharacterSelection == nil)
                                // Don't offer the export button if the Benchmark is for an unsupported version
                                // Mostly this is forward-thinking to the next expansion.
                                if benchmarkVersion == .dawntrail {
                                    Button("BENCHMARK_SLOT_EXPORT_BUTTON") {
                                        if let exportCharacter:
                                            CharacterDataSlot =
                                            characterListState.targetCharacters
                                            .filter({
                                                $0.id
                                                    == benchmarkCharacterSelection
                                            }).first
                                        {
                                            Benchmark.exportCharacterData(
                                                character: exportCharacter)
                                            characterListState
                                                .loadSourceFromRetail()
                                            benchmarkCharacterSelection = nil
                                        }
                                    }
                                    .disabled(
                                        benchmarkCharacterSelection == nil)

                                }
                            }
                            Spacer()
                        }
                        Divider()
                        VStack {
                            Text("AVAILABLE_SLOTS_LIST_LABEL").font(.title)
                            CharacterDataListView(
                                characterData: $characterListState
                                    .sourceCharacters,
                                selection: $importableCharacterSelection)
                            Button("BENCHMARK_SLOT_IMPORT_BUTTON") {
                                if let importCharacter: CharacterDataSlot =
                                    characterListState.sourceCharacters.filter({
                                        $0.id == importableCharacterSelection
                                    }).first
                                {
                                    Benchmark.importCharacterData(
                                        character: importCharacter)
                                    characterListState.loadTargetFromDemo()
                                    importableCharacterSelection = nil
                                }
                            }
                            .disabled(importableCharacterSelection == nil)
                            Spacer()
                        }
                    }
                    if discordCrew {
                        Text("BENCHMARK_DISCORD_BLURB")
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Button("BUTTON_DONE") {
                            dismiss()
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                    }
                }
            }.padding()
                .onAppear {
                    characterListState.loadTargetFromDemo()
                    characterListState.loadSourceFromRetail()
                }
        }
    }
}

#Preview {
    CharacterDataImportView()
}
