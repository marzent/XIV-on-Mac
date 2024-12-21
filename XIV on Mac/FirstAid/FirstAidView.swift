//
//  FirstAidWindowContent.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/18/23.
//

import SwiftUI

struct FirstAidView: View {
    @StateObject private var firstAidModel: FirstAidModel = .init()

    private func checkIfNotRunning() -> Bool {
        // Since we're deleting or otherwise mucking with files the game may be using or may re-write,
        // we generally want no copies running.
        if Wine.running(processName: "ffxiv_dx11.exe") {
            let alert: NSAlert = .init()
            alert.alertStyle = .warning
            alert.messageText = NSLocalizedString(
                "FIRSTAID_GAME_RUNNING", comment: "")
            alert.informativeText = NSLocalizedString(
                "FIRSTAID_GAME_RUNNING", comment: "")
            alert.addButton(
                withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
            alert.runModal()
            return false
        }
        return true
    }

    var cfgProblems: some View {
        ScrollView(showsIndicators: true) {
            LazyVStack(alignment: .leading) {
                ForEach(firstAidModel.cfgProblems) { oneProblem in
                    HStack {
                        switch oneProblem.type {
                        case .advisory:
                            if oneProblem.fixed {
                                Image(
                                    nsImage: NSImage(named: "CfgCheckAdvFixed")!
                                )
                            } else {
                                Image(
                                    nsImage: NSImage(
                                        named: "CfgCheckAdvFailed")!)
                            }
                        case .problem:
                            if oneProblem.fixed {
                                Image(
                                    nsImage: NSImage(
                                        named: "CfgCheckProbFixed")!)
                            } else {
                                Image(
                                    nsImage: NSImage(
                                        named: "CfgCheckProbFailed")!)
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
                            } else {
                                Text(oneProblem.explanation)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        Spacer()
                        if !oneProblem.fixed {
                            Button("FIRSTAID_CFGCHECK_FIX_BUTTON") {
                                self.firstAidModel.fix(condition: oneProblem)
                            }.padding(.trailing)
                        }
                    }
                }
            }
        }.frame(minHeight: 100)
    }

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
                    guard checkIfNotRunning() else {
                        return
                    }
                    let alert = NSAlert()
                    do {
                        try Dxvk.resetCache()
                        alert.alertStyle = .informational
                        alert.messageText = NSLocalizedString(
                            "DXVK_USER_CACHE_DELETED", comment: "")
                        alert.informativeText = NSLocalizedString(
                            "DXVK_USER_CACHE_DELETED_INFORMATIVE", comment: "")
                    } catch {
                        Log.error(error.localizedDescription)
                        alert.alertStyle = .warning
                        alert.messageText = NSLocalizedString(
                            "DXVK_USER_CACHE_DELETE_FAILED", comment: "")
                        alert.informativeText = NSLocalizedString(
                            "DXVK_USER_CACHE_DELETE_FAILED_INFORMATIVE",
                            comment: "")
                    }
                    alert.addButton(
                        withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                    alert.runModal()
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
                    guard checkIfNotRunning() else {
                        return
                    }
                    let alert = NSAlert()
                    do {
                        try FFXIVApp.resetConfiguration()
                        alert.alertStyle = .informational
                        alert.messageText = NSLocalizedString(
                            "GAME_CONFIG_RESET", comment: "")
                        alert.informativeText = NSLocalizedString(
                            "GAME_CONFIG_RESET_INFORMATIVE", comment: "")
                    } catch {
                        Log.error(error.localizedDescription)
                        alert.alertStyle = .warning
                        alert.messageText = NSLocalizedString(
                            "GAME_CONFIG_RESET_FAILED", comment: "")
                        alert.informativeText = NSLocalizedString(
                            "GAME_CONFIG_RESET_FAILED_INFORMATIVE", comment: "")
                    }
                    alert.addButton(
                        withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                    alert.runModal()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("FIRSTAID_CHECKUP_BLURB")
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.leading, .trailing])
                HStack {
                    Button("FIRSTAID_CHECKUP_BUTTON") {
                        firstAidModel.reloadCfg()
                    }
                    Spacer()
                }
            }
            Group {
                HStack {
                    switch $firstAidModel.cfgCheckOverallResult.wrappedValue {
                    case .noissue:
                        Image(nsImage: NSImage(named: "CfgCheckGood.tiff")!)
                        Text("FIRSTAID_CFGCHECK_GOOD_RESULT")
                    case .advisory:
                        Image(
                            nsImage: NSImage(named: "CfgCheckAdvFailed.tiff")!)
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
                if firstAidModel.cfgProblems.count > 0 {
                    cfgProblems
                }
            }
            .padding([.leading])
            Spacer()
        }
        .padding()
        .frame(width: 700, height: 820.0)
    }
}

struct FirstAidWindowContent_Previews: PreviewProvider {
    static var previews: some View {
        FirstAidView()
    }
}
