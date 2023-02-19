//
//  Benchmark.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 18.02.23.
//

import Cocoa

struct Benchmark {
    @available(*, unavailable) private init() {}

    private static let args = "SYS.Language=1 SYS.Fps=0 SYS.ScreenMode=2 SYS.WaterWet_DX11=1 SYS.OcclusionCulling_DX11=0 SYS.LodType_DX11=0 SYS.ReflectionType_DX11=3 SYS.AntiAliasing_DX11=1 SYS.TranslucentQuality_DX11=1 SYS.GrassQuality_DX11=3 SYS.ShadowLOD_DX11=0 SYS.ShadowVisibilityTypeSelf_DX11=1 SYS.ShadowVisibilityTypeOther_DX11=1 SYS.ShadowTextureSizeType_DX11=2 SYS.ShadowCascadeCountType_DX11=2 SYS.ShadowSoftShadowType_DX11=1 SYS.PhysicsTypeSelf_DX11=2 SYS.PhysicsTypeOther_DX11=2 SYS.TextureFilterQuality_DX11=2 SYS.TextureAnisotropicQuality_DX11=2 SYS.Vignetting_DX11=1 SYS.RadialBlur_DX11=1 SYS.SSAO_DX11=2 SYS.Glare_DX11=2 SYS.DepthOfField_DX11=1 SYS.ParallaxOcclusion_DX11=1 SYS.Tessellation_DX11=0 SYS.GlareRepresentation_DX11=1 SYS.DistortionWater_DX11=2"

    public static func launch() {
        let openPanel = NSOpenPanel()
        openPanel.message = NSLocalizedString("SELECT_BENCHMARK_PATH_PANEL_MESSAGE", comment: "")
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = true
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.begin { response in
            if response == .OK {
                if check(folder: openPanel.url) {
                    openPanel.close()
                    launchFrom(folder: openPanel.url!)
                    return
                }
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("BENCHMARK_TITLE", comment: "")
                alert.informativeText = NSLocalizedString("SELECT_BENCHMARK_PATH_ERROR_INFORMATIVE", comment: "")
                alert.alertStyle = .critical
                alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                alert.runModal()
                openPanel.close()
            }
        }
    }
    
    private static func launchFrom(folder: URL) {
        Log.information("Benchmark started on folder: \(folder.path)")
        let benchmarkExe = folder.appendingPathComponent("game/ffxiv_dx11.exe").path
        Wine.launch(command: "\"\(benchmarkExe)\" \(args)", blocking: true)
        guard let iniContents = try? String(contentsOf: folder.appendingPathComponent("ffxivbenchmarklauncher.ini"), encoding: .utf8) else {
            Log.error("Could not read ffxivbenchmarklauncher.ini")
            return
        }
        guard let score = iniContents.range(of: #"(?<=SCORE=)\d+"#, options: .regularExpression) else {
            Log.error("Could not parse parse benchmark score")
            return
        }
        guard let fps = iniContents.range(of: #"(?<=SCORE_FPSAVERAGE=)\d+"#, options: .regularExpression) else {
            Log.error("Could not parse parse benchmark fps")
            return
        }
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("BENCHMARK_TITLE", comment: "")
        alert.informativeText = String(format: NSLocalizedString("BENCHMARK_RESULT", comment: ""), String(iniContents[score]), String(iniContents[fps]))
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
        alert.runModal()
    }

    private static func check(folder: URL?) -> Bool {
        let fm = FileManager.default
        guard let folder = folder else {
            return false
        }
        guard fm.fileExists(atPath: folder.appendingPathComponent("ffxiv-endwalker-bench.exe").path) else {
            return false
        }
        guard fm.fileExists(atPath: folder.appendingPathComponent("game/ffxiv_dx11.exe").path) else {
            return false
        }
        return true
    }
}
