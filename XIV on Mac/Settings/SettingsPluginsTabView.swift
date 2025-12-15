//
//  SettingsPluginsTabView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/14/23.
//

import SwiftUI
import XIVLauncher

struct SettingsPluginsTabView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack {
            Text("SETTINGS_PLUGINS_WHAT_IS_DALAMUD_BLURB")
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .padding([.top, .leading, .trailing])
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Toggle(isOn: $viewModel.dalamudEnabled) {
                    Text("SETTINGS_PLUGINS_DALAMUD_ENABLE")
                }
                .padding(.leading)
                Spacer()
                Toggle(isOn: $viewModel.dalamudEntryPoint) {
                    Text("SETTINGS_PLUGINS_DALAMUD_ENTRYPOINT")
                }
                .padding(.leading)
                .disabled(!viewModel.dalamudEnabled)
                Spacer()
            }
            if !viewModel.dalamudEntryPoint {
                Text("SETTINGS_PLUGINS_DALAMUD_DELAY_BLURB")
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .padding([.top, .leading, .trailing])
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text("SETTINGS_PLUGINS_DALAMUD_DELAY_LABEL")
                        .padding([.leading])
                    TextField("0", text: $viewModel.dalamudDelay)
                        .frame(minWidth: 50)
                        .fixedSize(horizontal: true, vertical: false)
                    Text("SETTINGS_PLUGINS_DALAMUD_DELAY_UNITS")
                    Spacer()
                }
            }
            Divider().padding([.top])
            Text("SETTINGS_PLUGINS_DISCORD_BLURB")
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .padding([.top, .leading, .trailing])
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Toggle(isOn: $viewModel.discordBridge) {
                    Text("SETTINGS_PLUGINS_DISCORD_TOGGLE")
                }
                .padding(.leading)
                Spacer()
            }
            Divider().padding([.top])
            VStack(alignment: .leading, spacing: 8) {
                Text("SETTINGS_PLUGINS_DALAMUD_BRANCH_BLURB")
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .padding([.top, .trailing])
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .center, spacing: 12) {
                    Picker(selection: $viewModel.dalamudBetaKind, label: Text("SETTINGS_PLUGINS_DALAMUD_BRANCH_LABEL")) {
                        ForEach(viewModel.branches) { branch in
                            Text(branch.displayNameWithAvailability).tag(branch.track as String?)
                        }
                    }
                    .frame(minWidth: 260)
                    .disabled(viewModel.isFetching)

                    Button("SETTINGS_PLUGINS_DALAMUD_ENTER_BETA_KEY") {
                        viewModel.promptForBetaKey()
                    }
                    .disabled(viewModel.isFetching)
                }

                if let selected = viewModel.selectedBranch {
                    VStack(alignment: .leading, spacing: 4) {
                        if !(selected.isApplicableForCurrentGameVer ?? true) {
                            Text("SETTINGS_PLUGINS_DALAMUD_BRANCH_UNAVAILABLE")
                                .foregroundColor(.red)
                        }
                        if let desc = selected.description, !desc.isEmpty {
                            Text(desc)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        HStack(spacing: 12) {
                            Text(String(format: NSLocalizedString("SETTINGS_PLUGINS_DALAMUD_TRACK_FORMAT", comment: ""), selected.track)).font(.footnote)
                            Text(String(format: NSLocalizedString("SETTINGS_PLUGINS_DALAMUD_KEY_FORMAT", comment: ""), selected.key)).font(.footnote)
                        }
                    }
                    .padding(.top, 4)
                }

                if let error = viewModel.fetchError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }.disabled(viewModel.isFetching)
            .padding(.horizontal)
            Spacer()
        }
        .onAppear { viewModel.refreshBranches() }
    }
}

struct SettingsPluginsTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsPluginsTabView()
    }
}

private struct DalamudBranch: Identifiable, Codable, Equatable {
    let displayName: String
    let description: String?
    let track: String
    let hidden: Bool
    let key: String
    let assemblyVersion: String?
    let runtimeVersion: String?
    let runtimeRequired: Bool?
    let supportedGameVer: String?
    let isApplicableForCurrentGameVer: Bool?
    let downloadUrl: String?

    var id: String { track }

    var displayNameWithAvailability: String {
        if isApplicableForCurrentGameVer ?? true { return displayName }
        return "\(displayName) \(NSLocalizedString("SETTINGS_PLUGINS_DALAMUD_UNAVAILABLE_SUFFIX", comment: ""))"
    }
}

extension SettingsPluginsTabView {
    @MainActor class ViewModel: ObservableObject {
        @Published var dalamudEnabled: Bool = Settings.dalamudEnabled {
            didSet { Settings.dalamudEnabled = dalamudEnabled }
        }

        @Published var dalamudEntryPoint: Bool = Settings.dalamudEntryPoint {
            didSet { Settings.dalamudEntryPoint = dalamudEntryPoint }
        }

        @Published var dalamudDelay: String = .init(Settings.injectionDelay) {
            didSet { Settings.injectionDelay = Double(dalamudDelay) ?? 0 }
        }

        @Published var discordBridge: Bool = DiscordBridge.enabled {
            didSet { DiscordBridge.enabled = discordBridge }
        }

        @Published fileprivate var branches: [DalamudBranch] = []

        @Published var dalamudBetaKind: String = Settings.dalamudBetaKind {
            didSet {
                Settings.dalamudBetaKind = dalamudBetaKind
                if let betaKey = selectedBranch?.key {
                    Settings.dalamudBetaKey = betaKey
                }
                updateDalamud(dalamudBetaKind, Settings.dalamudBetaKey)
            }
        }

        @Published var isFetching: Bool = false
        @Published var fetchError: String? = nil

        fileprivate var selectedBranch: DalamudBranch? {
            return branches.first { $0.track == dalamudBetaKind }
        }

        func refreshBranches() {
            Task { await fetchBranchesAsync() }
        }

        private func fetchBranchesAsync() async {
            await MainActor.run {
                self.isFetching = true
                self.fetchError = nil
            }
            defer {
                Task { @MainActor in self.isFetching = false }
            }

            guard
                let url = URL(
                    string: "https://kamori.goats.dev/Dalamud/Release/Meta"
                )
            else {
                await MainActor.run { self.fetchError = NSLocalizedString("SETTINGS_PLUGINS_DALAMUD_FETCH_ERROR_INVALID_URL", comment: "") }
                return
            }

            do {
                let (data, response) = try await URLSession.shared.data(
                    from: url
                )
                if let http = response as? HTTPURLResponse,
                    http.statusCode != 200
                {
                    await MainActor.run {
                        self.fetchError = String(format: NSLocalizedString("SETTINGS_PLUGINS_DALAMUD_FETCH_ERROR_HTTP", comment: ""), http.statusCode)
                    }
                    return
                }
                let decoder = JSONDecoder()
                let dict = try decoder.decode(
                    [String: DalamudBranch].self,
                    from: data
                )
                let allBranches = Array(dict.values)
                let betaKey = Settings.dalamudBetaKey
                let filtered = allBranches.filter { br in
                    return !br.hidden
                        || (br.hidden && br.key == betaKey)
                }

                await MainActor.run {
                    self.branches = filtered
                    if filtered.first(where: {
                        $0.track == dalamudBetaKind && $0.key == Settings.dalamudBetaKey
                    }) != nil {
                        Log.information("Selected active Dalamud branch \(dalamudBetaKind)")
                    } else if let selectedBranch = filtered.first(where: {
                        $0.key == Settings.dalamudBetaKey
                    }) {
                        Log.information("Selected active Dalamud branch \(selectedBranch.track)")
                        self.dalamudBetaKind = selectedBranch.track
                    } else if let release = filtered.first(where: {
                        $0.track.lowercased() == "release"
                    }) {
                        Log.information("Falling back to latest stable Dalamud release")
                        self.dalamudBetaKind = release.track
                    } else {
                        Log.warning("Could not find a suitable Dalamud release or beta key")
                        self.dalamudBetaKind = ""
                    }
                }
                updateDalamud(dalamudBetaKind, Settings.dalamudBetaKey)
                
            } catch {
                await MainActor.run {
                    self.fetchError = String(format: NSLocalizedString("SETTINGS_PLUGINS_DALAMUD_FETCH_ERROR_GENERIC", comment: ""), error.localizedDescription)
                }
            }
        }

        func promptForBetaKey() {
            let alert: NSAlert = .init()
            alert.messageText = NSLocalizedString("SETTINGS_PLUGINS_DALAMUD_ENTER_BETA_KEY_TITLE", comment: "")
            alert.informativeText = NSLocalizedString("SETTINGS_PLUGINS_DALAMUD_ENTER_BETA_KEY_INFO", comment: "")
            alert.alertStyle = .informational
            let input = NSTextField(string: Settings.dalamudBetaKey)
            input.frame = NSRect(x: 0, y: 0, width: 280, height: 24)
            alert.accessoryView = input
            alert.addButton(
                withTitle: NSLocalizedString("BUTTON_OK", comment: "")
            )
            alert.addButton(
                withTitle: NSLocalizedString("BUTTON_CANCEL", comment: "")
            )
            let result = alert.runModal()
            if result == .alertFirstButtonReturn {
                let newKey = input.stringValue.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                Settings.dalamudBetaKey = newKey
                refreshBranches()
            }
        }
    }
}
