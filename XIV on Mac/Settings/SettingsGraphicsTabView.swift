//
//  SettingsGraphicsTabView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/14/23.
//

import SwiftUI

struct SettingsGraphicsTabView: View {
    @State var fpsLimited: Bool = Dxvk.options.maxFramerate != 0
    @State var fpsLimit: String = .init(Dxvk.options.maxFramerate)
    @State var async: Bool = Dxvk.options.async
    @State var hudScale: Double = Dxvk.options.hudScale
    @State var metal3Hud: Bool = Settings.metal3PerformanceOverlay
    @State var devinfo: Bool = Dxvk.options.hud["devinfo"] ?? false
    @State var fps: Bool = Dxvk.options.hud["fps"] ?? false
    @State var frametimes: Bool = Dxvk.options.hud["frametimes"] ?? false
    @State var submissions: Bool = Dxvk.options.hud["submissions"] ?? false
    @State var drawcalls: Bool = Dxvk.options.hud["drawcalls"] ?? false
    @State var pipelines: Bool = Dxvk.options.hud["pipelines"] ?? false
    @State var memory: Bool = Dxvk.options.hud["memory"] ?? false
    @State var gpuload: Bool = Dxvk.options.hud["gpuload"] ?? false
    @State var version: Bool = Dxvk.options.hud["version"] ?? false
    @State var api: Bool = Dxvk.options.hud["api"] ?? false
    @State var compiler: Bool = Dxvk.options.hud["compiler"] ?? true
    @State var retina: Bool = !Wine.retina
    @State var retinaStartupBugWorkaround: Bool = Wine.retinaStartupBugWorkaround
    @State var isConfirmingRetina: Bool = false
    
    var DXVKSavingEnabled: Bool = true
    var mapping: [String: Bool] = .init()
    var gfxSettingPseudoColumnWidth: CGFloat = 300.0
    
    func dxvkOption(binding: Binding<Bool>, changeVar: Bool, labelKey: String, settingKey: String) -> some View {
        return Toggle(isOn: binding) {
            Text(LocalizedStringKey(labelKey))
        }
        .onChange(of: changeVar) { newValue in
            Dxvk.options.hud[settingKey] = newValue
            if DXVKSavingEnabled {
                Dxvk.options.save()
            }
        }
    }
    
    func dvvkOptionsPair(leftOption: some View, rightOption: some View) -> some View {
        return HStack {
            Group {
                leftOption
                rightOption
            }.frame(width: gfxSettingPseudoColumnWidth, height: nil, alignment: .leading)
        }
    }
    
    func dxvkOptionsView() -> some View {
        return Group {
            Toggle(isOn: $metal3Hud) {
                Text("SETTINGS_GRAPHICS_METAL3_HUD")
            }
            .onChange(of: fpsLimited) { newValue in
                Dxvk.options.maxFramerate = newValue ? Int(fpsLimit) ?? 0 : 0
                Dxvk.options.save()
            }
            Divider()
            Text("SETTINGS_GRAPHICS_DXVK_HUD_HEADER")
                .frame(maxWidth: .infinity, alignment: .center)

            dvvkOptionsPair(leftOption:
                dxvkOption(binding: $devinfo, changeVar: devinfo, labelKey: "SETTINGS_GRAPHICS_DEVICE_INFO", settingKey: "devinfo"),
                rightOption:
                dxvkOption(binding: $gpuload, changeVar: devinfo, labelKey: "SETTINGS_GRAPHICS_GPU_LOAD", settingKey: "gpuload"))

            dvvkOptionsPair(leftOption:
                dxvkOption(binding: $fps, changeVar: fps, labelKey: "SETTINGS_GRAPHICS_FRAME_RATE_HUD", settingKey: "fps"),
                rightOption:
                dxvkOption(binding: $version, changeVar: version, labelKey: "SETTINGS_GRAPHICS_DXVK_VERSION", settingKey: "version"))

            dvvkOptionsPair(leftOption:
                dxvkOption(binding: $frametimes, changeVar: frametimes, labelKey: "SETTINGS_GRAPHICS_FRAME_TIME", settingKey: "frametimes"),
                rightOption:
                dxvkOption(binding: $api, changeVar: api, labelKey: "SETTINGS_GRAPHICS_FEATURE_LEVEL", settingKey: "api"))

            dvvkOptionsPair(leftOption:
                dxvkOption(binding: $submissions, changeVar: submissions, labelKey: "SETTINGS_GRAPHICS_BUFFER_SUBMISSIONS", settingKey: "submissions"),
                rightOption:
                dxvkOption(binding: $compiler, changeVar: compiler, labelKey: "SETTINGS_GRAPHICS_COMPILER", settingKey: "compiler"))

            dvvkOptionsPair(leftOption:
                dxvkOption(binding: $drawcalls, changeVar: drawcalls, labelKey: "SETTINGS_GRAPHICS_DRAWCALLS", settingKey: "drawcalls"),
                rightOption:
                dxvkOption(binding: $pipelines, changeVar: pipelines, labelKey: "SETTINGS_GRAPHICS_PIPELINES", settingKey: "pipelines"))

            dvvkOptionsPair(leftOption:
                dxvkOption(binding: $memory, changeVar: memory, labelKey: "SETTINGS_GRAPHICS_MEMORY", settingKey: "memory"),
                rightOption:
                Spacer())
            
            HStack {
                Button("SETTINGS_GRAPHICS_ALL_DXVK_ON_BUTTON") {
                    setAllDXVKSettings(to: true)
                }
                Button("SETTINGS_GRAPHICS_ALL_DXVK_OFF_BUTTON") {
                    setAllDXVKSettings(to: false)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var body: some View {
        VStack {
            HStack {
                Toggle(isOn: $fpsLimited) {
                    Text("SETTINGS_FPS_LIMIT")
                }
                .padding(.leading)
                .onChange(of: fpsLimited) { newValue in
                    Dxvk.options.maxFramerate = newValue ? Int(fpsLimit) ?? 0 : 0
                }
                
                TextField("SETTINGS_FPS_LIMIT_PLACEHOLDER", text: $fpsLimit)
                    .frame(minWidth: 50)
                    .fixedSize(horizontal: true, vertical: false)
                    .disabled(!fpsLimited)
                    .onChange(of: fpsLimit) { newValue in
                        Dxvk.options.maxFramerate = fpsLimited ? Int(newValue) ?? 0 : 0
                    }
                
                Text("SETTINGS_FPS_LIMIT_UNITS")
                    .padding(.trailing)
                
                Toggle(isOn: $async) {
                    Text("SETTINGS_GRAPHICS_ASYNC")
                }
                .padding(.leading)
                .onChange(of: async) { newValue in
                    Dxvk.options.async = newValue
                    Dxvk.options.save()
                }
                
                Spacer()
                    .padding(.horizontal)
            }
            GroupBox(label: Text("SETTINGS_GRAPHICS_HUD")) {
                Group {
                    VStack {
                        Text("SETTINGS_GRAPHICS_HUD_BLURB")
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            Text("SETTINGS_GRAPHICS_HUD_SCALE")
                            Slider(value: $hudScale, in: 0.0 ... 4.0, step: 1.0)
                                .onChange(of: hudScale) { newValue in
                                    Dxvk.options.hudScale = newValue
                                    Dxvk.options.save()
                                }
                            Button("SETTINGS_GRAPHICS_RESET_SCALE_BUTTON") {
                                hudScale = 1.0
                                Dxvk.options.hudScale = hudScale
                                Dxvk.options.save()
                            }
                        }
                        
                        dxvkOptionsView()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.horizontal)
            .frame(alignment: .leading)
            
            HStack {
                VStack {
                    Toggle(isOn: $retina) {
                        Text("SETTINGS_GRAPHICS_RETINA")
                    }
                    .padding(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: retina) { newValue in
                        if !newValue {
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
                                    retina = !newValue
                                }
                                return
                            }
                            // Allow the setting
                            Wine.retina = !newValue
                        }
                    }
                    if !retina {
                        Toggle(isOn: $retinaStartupBugWorkaround) {
                            Text("SETTINGS_GRAPHICS_RETINA_BUGFIX")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 30)
                    }
                    Spacer()
                }.frame(maxWidth: .infinity, alignment: .topLeading)
                Image(nsImage: NSImage(named: "PrefsGraphics") ?? NSImage())
                    .padding(.all)
            }
        }.frame(minWidth: 700, minHeight: 550)
    }
    
    func setAllDXVKSettings(to: Bool) {
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
        Dxvk.options.save()
    }
}

struct SettingsGraphicsTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsGraphicsTabView()
    }
}
