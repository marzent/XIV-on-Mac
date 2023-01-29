//
//  FirstAidWindowContent.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/18/23.
//

import SwiftUI

struct FirstAidWindowContent: View {
    @ObservedObject var firstAidController: FirstAidController = .init()

    var body: some View {
        VStack {
            Group {
                Text("FIRSTAID_SHADER_CACHE_HEADING")
                    .font(Font.title)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("FIRSTAID_SHADER_CACHE_BLURB")
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.leading, .trailing])
                Button("FIRSTAID_SHADER_CACHE_BUTTON") {
                    firstAidController.pressedDeleteUserCache(self)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            Group {
                Text("FIRSTAID_CONFIG_HEADING")
                    .font(Font.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("FIRSTAID_RESET_CONFIG_BLURB")
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.leading, .trailing])
                Button("FIRSTAID_RESET_CONFIG_BUTTON") {
                    firstAidController.pressedResetConfiguration(self)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("FIRSTAID_CHECKUP_BLURB")
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.leading, .trailing])
                HStack {
                    Button("FIRSTAID_CHECKUP_BUTTON") {
                        firstAidController.pressedCfgCheckup(self)
                    }
                    Spacer()
                }
            }
            Group {
                HStack {
                    switch $firstAidController.cfgCheckOverallResult.wrappedValue {
                        case .noissue:
                            Image(nsImage: NSImage(named: "CfgCheckGood.tiff")!)
                            Text("FIRSTAID_CFGCHECK_GOOD_RESULT")
                        case .advisory:
                            Image(nsImage: NSImage(named: "CfgCheckAdvFailed.tiff")!)
                            Text("FIRSTAID_CFGCHECK_ADVISORY_RESULT")
                        case .recommendation:
                            Image(nsImage: NSImage(named: "CfgCheckGood.tiff")!)
                            Text("FIRSTAID_CFGCHECK_RECOMMENDATION_RESULT")
                        case .problem:
                            Image(nsImage: NSImage(named: "CfgCheckProblems.tiff")!)
                            Text("FIRSTAID_CFGCHECK_PROBLEM_RESULT")
                    }
                    Spacer()
                }

                if firstAidController.cfgProblems.count > 0 {
                    ScrollView(showsIndicators: true) {
                        LazyVStack(alignment: .leading) {
                            ForEach(firstAidController.cfgProblems) { oneProblem in
                                HStack {
                                    switch oneProblem.type {
                                        case .advisory:
                                            if oneProblem.fixed {
                                                Image(nsImage: NSImage(named: "CfgCheckAdvFixed")!)
                                            }
                                            else {
                                                Image(nsImage: NSImage(named: "CfgCheckAdvFailed")!)
                                            }
                                        case .problem:
                                            if oneProblem.fixed {
                                                Image(nsImage: NSImage(named: "CfgCheckProbFixed")!)
                                            }
                                            else {
                                                Image(nsImage: NSImage(named: "CfgCheckProbFailed")!)
                                            }
                                        default:
                                            Image(nsImage: NSImage(named: "CfgCheckGood")!)
                                    }
                                    VStack {
                                        Text(oneProblem.title)
                                            .font(Font.headline)
                                            .frame(maxWidth: .infinity)
                                        if oneProblem.fixed {
                                            Text("FIRSTAID_CFGCHECK_FIXED")
                                                .font(Font.headline)
                                                .frame(maxWidth: .infinity)
                                        }
                                        else {
                                            Text(oneProblem.explanation)
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                    Spacer()
                                    if !oneProblem.fixed {
                                        Button("FIRSTAID_CFGCHECK_FIX_BUTTON") {
                                            self.firstAidController.pressedFix(condition: oneProblem)
                                        }.padding(.trailing)
                                    }
                                }
                            }
                        }
                    }.frame(minHeight: 100)
                }
            }
            .padding([.leading])
            Spacer()
        }
        .padding()
        .frame(width: 700, height: 820.0)
        .onAppear {
            firstAidController.willAppear()
        }
    }
}

struct FirstAidWindowContent_Previews: PreviewProvider {
    static var previews: some View {
        FirstAidWindowContent()
    }
}
