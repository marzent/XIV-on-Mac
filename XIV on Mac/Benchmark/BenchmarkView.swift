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
                Toggle(isOn: $setDefaults) {
                    Text("BENCHMARK_SET_DEFAULTS")
                }
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
            Button("BENCHMARK_START_BUTTON")
            {
                let benchmarkLocation : URL = URL(fileURLWithPath: benchmarkFolder)
                Benchmark.launchFrom(folder: benchmarkLocation, type:benchType, setDefaults: setDefaults)
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
