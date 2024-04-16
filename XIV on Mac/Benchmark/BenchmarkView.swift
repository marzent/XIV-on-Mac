//
//  BenchmarkView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 2/20/23.
//

import SwiftUI

struct BenchmarkView: View {
    @AppStorage(Benchmark.benchmarkFolderPref, store: .standard) var benchmarkFolder : String = ""
    
    @State var setDefaults : Bool = true
    @State var benchType : BenchmarkType = .hd
	@State var benchMode : BenchmarkMode = .benchmark
	@State var chosenCostume: BenchmarkCostumes = .jobGear
	
	@State var selectedAppearanceSlot : Int? = nil
	
	let benchmarkVersion: BenchmarkVersion = Benchmark.benchmarkVersion()
    
    var body: some View {
        VStack{
            HStack
            {
                Text("BENCHMARK_FOLDER_LABEL")
                    .font(.headline)
                Text(benchmarkFolder)
                    .frame(minWidth: 200)
                Spacer()
                Button("BENCHMARK_FOLDER_SELECT_BUTTON")
                {
                    Benchmark.chooseFolder()
                }
            }
			HStack
			{
				Picker(selection: $benchMode, label: Text("BENCHMARK_MODE_LABEL").font(.headline)) {
					Text("BENCHMARK_MODE_BENCHMARK_LABEL").tag(BenchmarkMode.benchmark)
					Text("BENCHMARK_MODE_CREATOR_LABEL").tag(BenchmarkMode.characterCreator)
				}.pickerStyle(RadioGroupPickerStyle())
				Spacer()
			}
			
            HStack
            {
                Picker(selection: $benchType, label: Text("BENCHMARK_TYPE_LABEL").font(.headline)) {
                    Text("BENCHMARK_TYPE_HD").tag(BenchmarkType.hd)
                    Text("BENCHMARK_TYPE_QHD").tag(BenchmarkType.wqhd)
                    Text("BENCHMARK_TYPE_CUSTOM").tag(BenchmarkType.custom)
                }.pickerStyle(RadioGroupPickerStyle())
                Spacer()
            }
			if benchmarkVersion == .dawntrail && benchMode == .benchmark
			{
				VStack
				{
					Picker(selection: $selectedAppearanceSlot, label: Text("BENCHMARK_CHARACTER_APPEARANCE").font(.headline))
							{
								Text("BENCHMARK_DEFAULT_APPEARANCE").tag(nil as Int?)
						ForEach(Benchmark.findAvailableDemoCharacters().sorted(by: {$0.id < $1.id}), content:
											{ oneCharacter in
												Text(oneCharacter.name).tag(oneCharacter.id as Int?)
											})
							}
						
					Picker(selection: $chosenCostume, label: Text("BENCHMARK_CHARACTER_COSTUME").font(.headline)) {
						ForEach(BenchmarkCostumes.allCases, id: \.self) { costume in
							Text(costume.localizedName)
								.tag(costume)
						}
					}
				}
				Spacer()
			}
			HStack
			{
				Toggle(isOn: $setDefaults) {
					Text("BENCHMARK_SET_DEFAULTS")
				}
				Spacer()

				Button("BENCHMARK_START_BUTTON")
				{
					Task
					{
						let benchmarkLocation : URL = URL(fileURLWithPath: benchmarkFolder)
						var options : BenchmarkOptions = BenchmarkOptions()
						options.type = benchType
						if let selectedAppearanceSlot = selectedAppearanceSlot {
							options.appearanceSlot = selectedAppearanceSlot
						}
						options.costume = chosenCostume
						options.mode = benchMode
						await Benchmark.launchFrom(folder: benchmarkLocation, options:options, setDefaults: setDefaults)
					}
				}
			}

        }
        .padding()
    }
}

struct BenchmarkView_Previews: PreviewProvider {
    static var previews: some View {
        BenchmarkView()
    }
}
