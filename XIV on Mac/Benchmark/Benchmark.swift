//
//  Benchmark.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 18.02.23.
//

import Cocoa

public enum BenchmarkType: UInt8 {
    case hd = 0
    case wqhd = 1
    case custom = 2
}

struct Benchmark {
    
    public static var benchmarkFolderPref : String = "benchmarkFolder"
    
    @available(*, unavailable) private init() {}

    // MOST but not all of these arguments are only honored at the command line, and ignored in the INI file.
    // Note that SYS.ScreenMode is required but omitted here; we dynically fill that in before use below.
    private static let args = "SYS.Language=1 SYS.Fps=0 SYS.WaterWet_DX11=1 SYS.OcclusionCulling_DX11=0 SYS.LodType_DX11=0 SYS.ReflectionType_DX11=3 SYS.AntiAliasing_DX11=1 SYS.TranslucentQuality_DX11=1 SYS.GrassQuality_DX11=3 SYS.ShadowLOD_DX11=0 SYS.ShadowVisibilityTypeSelf_DX11=1 SYS.ShadowVisibilityTypeOther_DX11=1 SYS.ShadowTextureSizeType_DX11=2 SYS.ShadowCascadeCountType_DX11=2 SYS.ShadowSoftShadowType_DX11=1 SYS.PhysicsTypeSelf_DX11=2 SYS.PhysicsTypeOther_DX11=2 SYS.TextureFilterQuality_DX11=2 SYS.TextureAnisotropicQuality_DX11=2 SYS.Vignetting_DX11=1 SYS.RadialBlur_DX11=1 SYS.SSAO_DX11=2 SYS.Glare_DX11=2 SYS.DepthOfField_DX11=1 SYS.ParallaxOcclusion_DX11=1 SYS.Tessellation_DX11=0 SYS.GlareRepresentation_DX11=1 SYS.DistortionWater_DX11=2"

    public static func chooseFolder() {
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
                    UserDefaults.standard.setValue(openPanel.url!.path, forKey: benchmarkFolderPref)
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
    
    private static func setupDefaultOptions(iniFilePath : URL) -> INIFile
    {
        var iniFile : INIFile = INIFile()

        // We're going to create a default file and write it out to the provided location.
        do {
            if (try? iniFilePath.checkResourceIsReachable()) ?? false {
                try? FileManager.default.removeItem(at: iniFilePath)
            }

            let defaultIniURL = Bundle.main.url(forResource: "ffxivbenchmarklauncher-Default", withExtension: "ini")!
            try FileManager.default.copyItem(at: defaultIniURL, to: iniFilePath)
        }
        catch let createError as NSError {
            Log.error("Bench: Could not create default Mac settings: \(createError.localizedDescription)")
        }

        // We have a few variables to set ourselves.
        guard let iniFileContents : String = try? String(contentsOf:iniFilePath) else
        {
            return iniFile
        }
        
        iniFile = INIFileDecoder.decode(iniFileContents)
        guard let evnSection : INIFileSection = iniFile.sections["EVN"] else
        {
            Log.error("Bench: Could not find EVN section in default INI file")
            return iniFile
        }
        
        
        // EVN contains all of the default operating parameters
        evnSection.setValue(key: "LANGUAGE", value: String(Settings.language.rawValue))
        evnSection.setValue(key: "REGION", value: String(Settings.language.rawValue)) // These two seem to have to match? At least for English, might need more region testing.

        return iniFile
    }
    
    public static func launchFrom(folder: URL, type : BenchmarkType, setDefaults : Bool) {
        var shouldSetDefaults : Bool = setDefaults
        Log.information("Benchmark started on folder: \(folder.path)")
        let benchmarkExe = folder.appendingPathComponent("game/ffxiv_dx11.exe").path
        let iniFilePath : URL = folder.appendingPathComponent("ffxivbenchmarklauncher.ini")
        
        var iniFile : INIFile = INIFile()
        if (!shouldSetDefaults)
        {
            // Make sure SOME ini file exists
            do
            {
                let iniContents : String = try String(contentsOf: iniFilePath)
                iniFile = INIFileDecoder.decode(iniContents)
            }
            catch let readError as NSError {
                Log.error("Benchmark: Could not Load existing settings: \(readError.localizedDescription)")
                // Couldn't load existing file, so we need to create one after all.
                shouldSetDefaults = true
            }
        }
        
        if (shouldSetDefaults)
        {
            iniFile = setupDefaultOptions(iniFilePath: iniFilePath)
        }
        
        var screenWidth : String = "1920"
        var screenHeight : String = "1080"
        var screenMode : String = String(FFXIVCFGDisplay_ScreenMode.Windowed.rawValue) // For whatever reason, it will only honor this setting on the CLI
        if  let evnSection : INIFileSection = iniFile.sections["EVN"]
        {
            // Set the screen mode selected
            switch type
            {
            case .hd:
                break
            case .wqhd:
                screenWidth = "2560"
                screenHeight = "1440"
            case .custom:
                screenMode =  String(FFXIVCFGDisplay_ScreenMode.Borderless.rawValue)
                // It's not actually important to set these in Borderless, but if you don't it displays lies.
                if let mainScreen = NSScreen.main
                {
                    let mainScreenFrame = mainScreen.frame
                    let retina : Bool = Wine.retina
                    screenWidth = String(Int(mainScreenFrame.width) * (retina ? 2 : 1))
                    screenHeight = String(Int(mainScreenFrame.height) * (retina ? 2 : 1))
                }
            }
            evnSection.setValue(key: "SCREENWIDTH_DX11", value:screenWidth)
            evnSection.setValue(key: "SCREENHEIGHT_DX11", value:screenHeight)
        }
        
        // Write out our modified INI file
        do
        {
            let modifiedINIContents = try INIFileEncoder.encode(iniFile)
            try modifiedINIContents.write(to: iniFilePath, atomically: true, encoding: .utf8)
        }
        catch let writeError as NSError
        {
            Log.error("Benchmark: Could not save new settings: \(writeError.localizedDescription)")
        }
        
        let finalArgs = "\(args) SYS.ScreenMode=\(screenMode)"
        Wine.launch(command: "\"\(benchmarkExe)\" \(finalArgs)", blocking: true)
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
        guard fm.fileExists(atPath: folder.appendingPathComponent("ffxiv-endwalker-bench.exe").path) ||
              fm.fileExists(atPath: folder.appendingPathComponent("ffxiv-dawntrail-bench.exe").path) else {
            return false
        }
        guard fm.fileExists(atPath: folder.appendingPathComponent("game/ffxiv_dx11.exe").path) else {
            return false
        }
        return true
    }
}
