//
//  SettingsGraphicsTabView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/14/23.
//

import SwiftUI

struct SettingsGraphicsTabView: View {
    @StateObject private var viewModel = ViewModel()

    func dvvkOptionsPair(leftOption: some View, rightOption: some View) -> some View {
        return HStack {
            Group {
                leftOption
                rightOption
            }.frame(width: 300.0, height: nil, alignment: .leading)
        }
    }

    func labeledScaleSlider(maxScale: Int) -> some View {
        func labelOffsetAt(_ index: Int, _ maxScale: Int) -> CGFloat {
            switch index {
            case 0:
                return 2.7
            case maxScale:
                return -2
            default:
                return 0
            }
        }
        return VStack(spacing: 5) {
            Slider(value: $viewModel.hudScale, in: 0.0 ... Double(maxScale))
            HStack(spacing: 0) {
                ForEach(0 ... maxScale, id: \.self) { index in
                    VStack {
                        Text("x\(index)")
                    }
                    .offset(x: labelOffsetAt(index, maxScale))
                    if index != maxScale {
                        Spacer()
                    }
                }
            }
        }
    }

    var dxvkOptionsView: some View {
        Group {
            Toggle(isOn: $viewModel.metal3Hud) {
                Text("SETTINGS_GRAPHICS_METAL3_HUD")
            }
            Divider()
            Text("SETTINGS_GRAPHICS_DXVK_HUD_HEADER")
                .frame(maxWidth: .infinity, alignment: .center)
            
            Group {
                dvvkOptionsPair(
                    leftOption: Toggle(isOn: $viewModel.devinfo) { Text(LocalizedStringKey("SETTINGS_GRAPHICS_DEVICE_INFO")) },
                    rightOption: Toggle(isOn: $viewModel.gpuload) { Text(LocalizedStringKey("SETTINGS_GRAPHICS_GPU_LOAD")) }
                )
                dvvkOptionsPair(
                    leftOption: Toggle(isOn: $viewModel.fps) { Text(LocalizedStringKey("SETTINGS_GRAPHICS_FRAME_RATE_HUD")) },
                    rightOption: Toggle(isOn: $viewModel.version) { Text(LocalizedStringKey("SETTINGS_GRAPHICS_DXVK_VERSION")) }
                )
                dvvkOptionsPair(
                    leftOption: Toggle(isOn: $viewModel.frametimes) { Text(LocalizedStringKey("SETTINGS_GRAPHICS_FRAME_TIME")) },
                    rightOption: Toggle(isOn: $viewModel.api) { Text(LocalizedStringKey("SETTINGS_GRAPHICS_FEATURE_LEVEL")) }
                )
                dvvkOptionsPair(
                    leftOption: Toggle(isOn: $viewModel.submissions) { Text(LocalizedStringKey("SETTINGS_GRAPHICS_BUFFER_SUBMISSIONS")) },
                    rightOption: Toggle(isOn: $viewModel.compiler) { Text(LocalizedStringKey("SETTINGS_GRAPHICS_COMPILER")) }
                )
                dvvkOptionsPair(
                    leftOption: Toggle(isOn: $viewModel.drawcalls) { Text(LocalizedStringKey("SETTINGS_GRAPHICS_DRAWCALLS")) },
                    rightOption: Toggle(isOn: $viewModel.pipelines) { Text(LocalizedStringKey("SETTINGS_GRAPHICS_PIPELINES")) }
                )
                dvvkOptionsPair(
                    leftOption: Toggle(isOn: $viewModel.memory) { Text(LocalizedStringKey("SETTINGS_GRAPHICS_MEMORY")) },
                    rightOption: Spacer()
                )
                HStack {
                    Button("SETTINGS_GRAPHICS_ALL_DXVK_ON_BUTTON") {
                        viewModel.setAllDXVKSettings(to: true)
                    }
                    Button("SETTINGS_GRAPHICS_ALL_DXVK_OFF_BUTTON") {
                        viewModel.setAllDXVKSettings(to: false)
                    }
                }
            }.disabled(viewModel.dxmtEnabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        VStack {
            VStack {
                HStack {
                    Toggle(isOn: $viewModel.dxmtEnabled) {
                        Text("DXMT_ENABLED")
                    }
                    .padding(.leading)
                    Spacer()
                        .padding(.horizontal)
                }
                HStack {
                    Toggle(isOn: $viewModel.fpsLimited) {
                        Text("SETTINGS_FPS_LIMIT")
                    }.disabled(viewModel.dxmtEnabled)
                    .padding(.leading)
                    TextField("SETTINGS_FPS_LIMIT_PLACEHOLDER", text: $viewModel.fpsLimit)
                        .frame(minWidth: 50)
                        .fixedSize(horizontal: true, vertical: false)
                        .disabled(!viewModel.fpsLimited)
                    Text("SETTINGS_FPS_LIMIT_UNITS")
                        .padding(.trailing)
                    Toggle(isOn: $viewModel.asyncShaders) {
                        Text("SETTINGS_GRAPHICS_ASYNC")
                    }.disabled(viewModel.dxmtEnabled)
                    .padding(.leading)
                    Spacer()
                        .padding(.horizontal)
                }
            }
            GroupBox(label: Text("SETTINGS_GRAPHICS_HUD")) {
                Group {
                    VStack {
                        Text("SETTINGS_GRAPHICS_HUD_BLURB")
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 30) {
                            Text("SETTINGS_GRAPHICS_HUD_SCALE")
                            labeledScaleSlider(maxScale: 4)
                            Button("SETTINGS_GRAPHICS_RESET_SCALE_BUTTON") {
                                viewModel.hudScale = 1.0
                            }
                        }.disabled(viewModel.dxmtEnabled)
                        dxvkOptionsView
                    }
                }
                .padding(.horizontal)
            }
            .padding(.horizontal)
            .frame(alignment: .leading)

            HStack {
                VStack {
                    Toggle(isOn: $viewModel.macScaling) {
                        Text("SETTINGS_GRAPHICS_RETINA")
                    }
                    .padding([.leading, .top])
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                }.frame(maxWidth: .infinity, alignment: .topLeading)
                Image(nsImage: NSImage(named: "PrefsGraphics") ?? NSImage())
                    .padding(.all)
            }
        }
        .padding(.top)
    }
}

struct SettingsGraphicsTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsGraphicsTabView()
    }
}

extension SettingsGraphicsTabView {
    @MainActor class ViewModel: ObservableObject {
        @Published var dxmtEnabled: Bool = Settings.dxmtEnabled {
            didSet { Settings.dxmtEnabled = dxmtEnabled }
        }

        @Published var fpsLimited: Bool = Dxvk.options.maxFramerate != 0 {
            didSet { updateFpsLimit() }
        }

        @Published var fpsLimit: String = .init(Dxvk.options.maxFramerate) {
            didSet { updateFpsLimit() }
        }

        @Published var asyncShaders: Bool = Dxvk.options.asyncShaders {
            didSet {
                Dxvk.options.asyncShaders = asyncShaders
                Dxvk.options.save()
            }
        }

        @Published var hudScale: Double = Dxvk.options.hudScale {
            didSet {
                Dxvk.options.hudScale = hudScale
                Dxvk.options.save()
            }
        }

        @Published var metal3Hud: Bool = Settings.metal3PerformanceOverlay {
            didSet { Settings.metal3PerformanceOverlay = metal3Hud }
        }

        @Published var devinfo: Bool = Dxvk.options.getHud(option: "devinfo") {
            didSet { try! Dxvk.options.setHud(option: "devinfo", to: devinfo) }
        }

        @Published var fps: Bool = Dxvk.options.getHud(option: "fps") {
            didSet { try! Dxvk.options.setHud(option: "fps", to: fps) }
        }

        @Published var frametimes: Bool = Dxvk.options.getHud(option: "frametimes") {
            didSet { try! Dxvk.options.setHud(option: "frametimes", to: frametimes) }
        }

        @Published var submissions: Bool = Dxvk.options.getHud(option: "submissions") {
            didSet { try! Dxvk.options.setHud(option: "submissions", to: submissions) }
        }

        @Published var drawcalls: Bool = Dxvk.options.getHud(option: "drawcalls") {
            didSet { try! Dxvk.options.setHud(option: "drawcalls", to: drawcalls) }
        }

        @Published var pipelines: Bool = Dxvk.options.getHud(option: "pipelines") {
            didSet { try! Dxvk.options.setHud(option: "pipelines", to: pipelines) }
        }

        @Published var memory: Bool = Dxvk.options.getHud(option: "memory") {
            didSet { try! Dxvk.options.setHud(option: "memory", to: memory) }
        }

        @Published var gpuload: Bool = Dxvk.options.getHud(option: "gpuload") {
            didSet { try! Dxvk.options.setHud(option: "gpuload", to: gpuload) }
        }

        @Published var version: Bool = Dxvk.options.getHud(option: "version") {
            didSet { try! Dxvk.options.setHud(option: "version", to: version) }
        }

        @Published var api: Bool = Dxvk.options.getHud(option: "api") {
            didSet { try! Dxvk.options.setHud(option: "api", to: api) }
        }

        @Published var compiler: Bool = Dxvk.options.getHud(option: "compiler") {
            didSet { try! Dxvk.options.setHud(option: "compiler", to: compiler) }
        }

        @Published var macScaling: Bool = !Wine.retina {
            didSet {
                if !macScaling {
                    // User is turning OFF scaling mode (enabling Retina mode)
                    // This might be a bad idea...
                    let alert: NSAlert = .init()
                    alert.messageText = NSLocalizedString("RETINA_WARNING", comment: "")
                    alert.informativeText = NSLocalizedString("RETINA_WARNING_INFORMATIVE", comment: "")
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: NSLocalizedString("RETINA_ENABLE_BUTTON", comment: ""))
                    alert.addButton(withTitle: NSLocalizedString("BUTTON_CANCEL", comment: ""))
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

        func setAllDXVKSettings(to: Bool) {
            Dxvk.options.setAllHudOptions(to: to)
            devinfo = to
            fps = to
            frametimes = to
            submissions = to
            drawcalls = to
            pipelines = to
            memory = to
            gpuload = to
            version = to
            api = to
            compiler = to
        }

        private func updateFpsLimit() {
            Dxvk.options.maxFramerate = fpsLimited ? Int(fpsLimit) ?? 0 : 0
            Dxvk.options.save()
        }
    }
}
