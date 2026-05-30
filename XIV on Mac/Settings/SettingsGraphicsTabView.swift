//
//  SettingsGraphicsTabView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/14/23.
//

import SwiftUI

struct SettingsGraphicsTabView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $viewModel.metalFxSpatialEnabled) {
                    Text("METALFX_SPATIAL_ENABLED")
                }

                HStack(spacing: 8) {
                    Toggle(isOn: $viewModel.fpsLimited) {
                        Text("SETTINGS_FPS_LIMIT")
                    }
                    TextField(
                        "SETTINGS_FPS_LIMIT_PLACEHOLDER",
                        text: $viewModel.fpsLimit
                    )
                    .frame(minWidth: 50)
                    .fixedSize(horizontal: true, vertical: false)
                    .disabled(!viewModel.fpsLimited)
                    Text("SETTINGS_FPS_LIMIT_UNITS")
                }

                Toggle(isOn: $viewModel.macScaling) {
                    Text("SETTINGS_GRAPHICS_RETINA")
                }
            }
            .padding(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack {
                Spacer()
                Image(nsImage: NSImage(named: "PrefsGraphics") ?? NSImage())
                    .padding([.trailing, .bottom])
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SettingsGraphicsTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsGraphicsTabView()
    }
}

extension SettingsGraphicsTabView {
    @MainActor class ViewModel: ObservableObject {
        @Published var metalFxSpatialEnabled: Bool = Settings
            .metalFxSpatialEnabled
        {
            didSet { Settings.metalFxSpatialEnabled = metalFxSpatialEnabled }
        }

        @Published var fpsLimited: Bool = Settings.maxFramerate != 0 {
            didSet { updateFpsLimit() }
        }

        @Published var fpsLimit: String = String(Settings.maxFramerate) {
            didSet { updateFpsLimit() }
        }

        @Published var metal3Hud: Bool = Settings.metal3PerformanceOverlay {
            didSet { Settings.metal3PerformanceOverlay = metal3Hud }
        }

        @Published var macScaling: Bool = !Wine.retina {
            didSet {
                if !macScaling {
                    // User is turning OFF scaling mode (enabling Retina mode)
                    // This might be a bad idea...
                    let alert: NSAlert = .init()
                    alert.messageText = NSLocalizedString(
                        "RETINA_WARNING", comment: "")
                    alert.informativeText = NSLocalizedString(
                        "RETINA_WARNING_INFORMATIVE", comment: "")
                    alert.alertStyle = .warning
                    alert.addButton(
                        withTitle: NSLocalizedString(
                            "RETINA_ENABLE_BUTTON", comment: ""))
                    alert.addButton(
                        withTitle: NSLocalizedString(
                            "BUTTON_CANCEL", comment: ""))
                    let result = alert.runModal()
                    guard result == .alertFirstButtonReturn else {
                        DispatchQueue.main.async {
                            // Change it back
                            self.macScaling = true
                        }
                        return
                    }
                }
                Wine.retina = !macScaling
            }
        }

        private func updateFpsLimit() {
            Settings.maxFramerate = fpsLimited ? UInt32(fpsLimit) ?? 0 : 0
        }
    }
}
