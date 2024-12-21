//
//  Benchmark.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 18.02.23.
//

import Cocoa
import SwiftUI

public enum BenchmarkMode {
    case benchmark
    case characterCreator
}

public enum BenchmarkType: UInt8 {
    case hd = 0
    case wqhd = 1
    case custom = 2
}

// Some options/features have only been tested against
// specific benchmarks.
public enum BenchmarkVersion {
    case unknown
    case endwalker
    case dawntrail
}

public enum BenchmarkCostumes: UInt8, Equatable, CaseIterable {
    case jobGear = 0  // In Dawntrail, lvl 100 Viper
    case racialGear = 1
    case dreadwyrm = 2
    case ironworks = 3
    case alexandrian = 4
    case fallingDragon = 5
    case stormElite = 6
    case serpentElite = 7
    case flameElite = 8
    case genji = 9
    case omega = 10
    case hellhound = 11
    case dwarven = 12
    case edenmorn = 13
    case anabaseios = 14
    case legacy = 15
    case wildRose = 16
    case moonward = 17
    case strife = 18
    case leonheart = 19
    case tantalus = 20
    case highSummoner = 21
    case lightning = 22
    case sharlayanProdigy = 23
    case lucianPrince = 24
    case metian = 25
    case swine = 26

    var localizedName: LocalizedStringKey {
        LocalizedStringKey(String(format: "BENCHMARK_COSTUME_%d", rawValue))
    }
}

struct BenchmarkOptions {
    var mode: BenchmarkMode = .benchmark
    var type: BenchmarkType = .hd
    var appearanceData: URL? = nil  // A URL to a character appears .dat file, if any. Implies it needs to be copied in!
    var appearanceSlot: Int? = nil
    var costume: BenchmarkCostumes = .jobGear
}

struct Benchmark {

    public static var benchmarkFolderPref: String = "benchmarkFolder"

    @available(*, unavailable) private init() {}

    // MOST but not all of these arguments are only honored at the command line, and ignored in the INI file.
    // Note that SYS.ScreenMode is required but omitted here; we dynamically fill that in before use below.
    private static let args: [String] = [
        "SYS.Language=1",
        "SYS.Fps=0",
        "SYS.WaterWet_DX11=1",
        "SYS.OcclusionCulling_DX11=0",
        "SYS.LodType_DX11=0",
        "SYS.ReflectionType_DX11=3",
        "SYS.AntiAliasing_DX11=1",
        "SYS.TranslucentQuality_DX11=1",
        "SYS.GrassQuality_DX11=3",
        "SYS.ShadowLOD_DX11=0",
        "SYS.ShadowVisibilityTypeSelf_DX11=1",
        "SYS.ShadowVisibilityTypeOther_DX11=1",
        "SYS.ShadowTextureSizeType_DX11=2",
        "SYS.ShadowCascadeCountType_DX11=2",
        "SYS.ShadowSoftShadowType_DX11=1",
        "SYS.PhysicsTypeSelf_DX11=2",
        "SYS.PhysicsTypeOther_DX11=2",
        "SYS.TextureFilterQuality_DX11=2",
        "SYS.TextureAnisotropicQuality_DX11=2",
        "SYS.Vignetting_DX11=1",
        "SYS.RadialBlur_DX11=1",
        "SYS.SSAO_DX11=2",
        "SYS.Glare_DX11=2",
        "SYS.DepthOfField_DX11=1",
        "SYS.ParallaxOcclusion_DX11=1",
        "SYS.Tessellation_DX11=0",
        "SYS.GlareRepresentation_DX11=1",
        "SYS.DistortionWater_DX11=2",
    ]
    static let seDemoLocationURL = Util.userHome.appendingPathComponent(
        "/Documents/My Games/FINAL FANTASY XIV - A Realm Reborn (Benchmark)/",
        isDirectory: true)

    public static func findAvailableDemoCharacters() -> [CharacterDataSlot] {
        return findAvailableCharacters(
            location: seDemoLocationURL, pattern: "FFXIV_CHARA_BENCH")
    }

    public static func findAvailableRetailCharacters() -> [CharacterDataSlot] {
        return findAvailableCharacters(
            location: Settings.gameConfigPath, pattern: "FFXIV_CHARA_")
    }

    public static func findAvailableDiscordTeamCharacters()
        -> [CharacterDataSlot]
    {
        return findAvailableCharacters(
            location: Bundle.main.resourceURL!, pattern: "DISCORD_TEAM_")
    }

    // Looks for character appearances exported from the game and return the path to any we find
    public static func findAvailableCharacters(location: URL, pattern: String)
        -> [CharacterDataSlot]
    {
        var ReturnMe: [CharacterDataSlot] = [CharacterDataSlot]()

        let enumerator = FileManager.default.enumerator(
            at: location,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants],
            errorHandler: { (url, error) -> Bool in
                Log.error(
                    "Bench: directoryEnumerator error at \(url): \(error)")
                return true
            })!
        for case let oneFileURL as URL in enumerator {
            if oneFileURL.pathExtension == "dat"
                && oneFileURL.lastPathComponent.starts(with: pattern)
            {
                // Found what looks like a character appearance data file!
                // The slot number is just the end part of the filename
                if let slot: Int = Int(
                    oneFileURL.lastPathComponent.components(
                        separatedBy: CharacterSet.decimalDigits.inverted
                    ).joined())
                {
                    ReturnMe.append(
                        CharacterDataSlot(id: slot, dataURL: oneFileURL))
                }
            }
        }

        return ReturnMe
    }

    public static func copy(
        character: CharacterDataSlot, from: URL, to: URL,
        existingCharacters: [CharacterDataSlot], format: String
    ) {
        // Need to find a free slot on the target, because the game only accepts a limited amount. (40 in Dawntrail)
        let existingCharacters: [CharacterDataSlot] = existingCharacters.sorted(
            by: { $0.id < $1.id })
        var slotNumber: Int = 1
        for oneCharacter in existingCharacters {
            if oneCharacter.id != slotNumber {
                // Found a free slot or a gap
                break
            }
            slotNumber += 1
        }
        guard slotNumber <= 40 else { return }

        let destURL = to.appendingPathComponent(
            String(format: format, slotNumber), isDirectory: false)
        try? FileManager.default.copyItem(at: from, to: destURL)
    }

    public static func importCharacterData(character: CharacterDataSlot) {
        guard let sourceURL: URL = character.path else { return }
        copy(
            character: character, from: sourceURL, to: seDemoLocationURL,
            existingCharacters: Benchmark.findAvailableDemoCharacters(),
            format: "FFXIV_CHARA_BENCH%02d.dat")
    }

    public static func exportCharacterData(character: CharacterDataSlot) {
        guard let sourceURL: URL = character.path else { return }
        copy(
            character: character, from: sourceURL, to: Settings.gameConfigPath,
            existingCharacters: Benchmark.findAvailableRetailCharacters(),
            format: "FFXIV_CHARA_%02d.dat")
    }

    public static func benchmarkVersion() -> BenchmarkVersion {
        if let benchmarkPath: String = UserDefaults.standard.string(
            forKey: benchmarkFolderPref)
        {
            let benchmarkFolder: URL = URL(fileURLWithPath: benchmarkPath)
            do {
                if try benchmarkFolder.appendingPathComponent(
                    "ffxiv-dawntrail-bench.exe", isDirectory: false
                ).checkResourceIsReachable() {
                    return .dawntrail
                }
            } catch {
            }
            do {
                if try benchmarkFolder.appendingPathComponent(
                    "ffxiv-endwalker-bench.exe", isDirectory: false
                ).checkResourceIsReachable() {
                    return .endwalker
                }
            } catch {
            }

        }
        return .unknown
    }

    public static func chooseFolder() {
        let openPanel = NSOpenPanel()
        openPanel.message = NSLocalizedString(
            "SELECT_BENCHMARK_PATH_PANEL_MESSAGE", comment: "")
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
                    UserDefaults.standard.setValue(
                        openPanel.url!.path, forKey: benchmarkFolderPref)
                    return
                }
                let alert = NSAlert()
                alert.messageText = NSLocalizedString(
                    "BENCHMARK_TITLE", comment: "")
                alert.informativeText = NSLocalizedString(
                    "SELECT_BENCHMARK_PATH_ERROR_INFORMATIVE", comment: "")
                alert.alertStyle = .critical
                alert.addButton(
                    withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                alert.runModal()
                openPanel.close()
            }
        }
    }

    private static func setupDefaultOptions(iniFilePath: URL) -> INIFile {
        var iniFile: INIFile = INIFile()

        // We're going to create a default file and write it out to the provided location.
        do {
            if (try? iniFilePath.checkResourceIsReachable()) ?? false {
                try? FileManager.default.removeItem(at: iniFilePath)
            }

            let defaultIniURL = Bundle.main.url(
                forResource: "ffxivbenchmarklauncher-Default",
                withExtension: "ini")!
            try FileManager.default.copyItem(at: defaultIniURL, to: iniFilePath)
        } catch let createError as NSError {
            Log.error(
                "Bench: Could not create default Mac settings: \(createError.localizedDescription)"
            )
        }

        // We have a few variables to set ourselves.
        guard let iniFileContents: String = try? String(contentsOf: iniFilePath)
        else {
            return iniFile
        }

        iniFile = INIFileDecoder.decode(iniFileContents)
        guard let evnSection: INIFileSection = iniFile.sections["EVN"] else {
            Log.error("Bench: Could not find EVN section in default INI file")
            return iniFile
        }

        // EVN contains all of the default operating parameters
        evnSection.setValue(
            key: "LANGUAGE", value: String(Settings.language.rawValue))
        evnSection.setValue(
            key: "REGION", value: String(Settings.language.rawValue))  // These two seem to have to match? At least for English, might need more region testing.

        return iniFile
    }

    public static func launchFrom(
        folder: URL, options: BenchmarkOptions, setDefaults: Bool
    ) async {
        var shouldSetDefaults: Bool = setDefaults
        Log.information("Benchmark started on folder: \(folder.path)")
        let benchmarkExe = folder.appendingPathComponent("game/ffxiv_dx11.exe")
            .path
        let iniFilePath: URL = folder.appendingPathComponent(
            "ffxivbenchmarklauncher.ini")

        var iniFile: INIFile = INIFile()
        if !shouldSetDefaults {
            // Make sure SOME ini file exists
            do {
                let iniContents: String = try String(contentsOf: iniFilePath)
                iniFile = INIFileDecoder.decode(iniContents)
            } catch let readError as NSError {
                Log.error(
                    "Benchmark: Could not Load existing settings: \(readError.localizedDescription)"
                )
                // Couldn't load existing file, so we need to create one after all.
                shouldSetDefaults = true
            }
        }

        if shouldSetDefaults {
            iniFile = setupDefaultOptions(iniFilePath: iniFilePath)
        }

        var screenWidth: String = "1920"
        var screenHeight: String = "1080"
        var screenMode: String = String(
            FFXIVCFGDisplay_ScreenMode.Windowed.rawValue)  // For whatever reason, it will only honor this setting on the CLI
        if let evnSection: INIFileSection = iniFile.sections["EVN"] {
            // Set the screen mode selected
            switch options.type
            {
            case .hd:
                break
            case .wqhd:
                screenWidth = "2560"
                screenHeight = "1440"
            case .custom:
                screenMode = String(
                    FFXIVCFGDisplay_ScreenMode.Borderless.rawValue)
                // It's not actually important to set these in Borderless, but if you don't it displays lies.
                if let mainScreen = NSScreen.main {
                    let mainScreenFrame = mainScreen.frame
                    let retina: Bool = Wine.retina
                    screenWidth = String(
                        Int(mainScreenFrame.width) * (retina ? 2 : 1))
                    screenHeight = String(
                        Int(mainScreenFrame.height) * (retina ? 2 : 1))
                }
            }
            evnSection.setValue(key: "SCREENWIDTH_DX11", value: screenWidth)
            evnSection.setValue(key: "SCREENHEIGHT_DX11", value: screenHeight)
        }

        if options.mode == .benchmark {
            if let castingSection: INIFileSection = iniFile.sections["CASTING"]
            {
                if let appearanceSlot = options.appearanceSlot {
                    castingSection.setValue(
                        key: "CASTING_SAVEDATAINDEX",
                        value: String(appearanceSlot))
                }
                castingSection.setValue(
                    key: "CASTING_EQUIPMENT",
                    value: String(options.costume.rawValue))
            }
        }

        // Write out our modified INI file
        do {
            let modifiedINIContents = try INIFileEncoder.encode(iniFile)
            try modifiedINIContents.write(
                to: iniFilePath, atomically: true, encoding: .utf8)
        } catch let writeError as NSError {
            Log.error(
                "Benchmark: Could not save new settings: \(writeError.localizedDescription)"
            )
        }
        var finalArgs = args
        finalArgs.append("SYS.ScreenMode=\(screenMode)")
        finalArgs.append("SYS.ScreenWidth=\(screenWidth)")
        finalArgs.append("SYS.ScreenHeight=\(screenHeight)")
        if options.mode == .characterCreator {
            finalArgs.append("Bench.CharacterCreation=1")
        }

        Wine.launch(
            command: "\"\(benchmarkExe)\" \(finalArgs.joined(separator: " "))",
            blocking: true)
        guard
            let iniContents = try? String(
                contentsOf: folder.appendingPathComponent(
                    "ffxivbenchmarklauncher.ini"), encoding: .utf8)
        else {
            Log.error("Could not read ffxivbenchmarklauncher.ini")
            return
        }
        guard
            let score = iniContents.range(
                of: #"(?<=SCORE=)\d+"#, options: .regularExpression)
        else {
            Log.error("Could not parse parse benchmark score")
            return
        }
        guard
            let fps = iniContents.range(
                of: #"(?<=SCORE_FPSAVERAGE=)\d+"#, options: .regularExpression)
        else {
            Log.error("Could not parse parse benchmark fps")
            return
        }
        await MainActor.run {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString(
                "BENCHMARK_TITLE", comment: "")
            alert.informativeText = String(
                format: NSLocalizedString("BENCHMARK_RESULT", comment: ""),
                String(iniContents[score]), String(iniContents[fps]))
            alert.alertStyle = .informational
            alert.addButton(
                withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
            alert.runModal()
        }
    }

    private static func check(folder: URL?) -> Bool {
        let fm = FileManager.default
        guard let folder = folder else {
            return false
        }
        guard
            fm.fileExists(
                atPath: folder.appendingPathComponent(
                    "ffxiv-endwalker-bench.exe"
                ).path)
                || fm.fileExists(
                    atPath: folder.appendingPathComponent(
                        "ffxiv-dawntrail-bench.exe"
                    ).path)
        else {
            return false
        }
        guard
            fm.fileExists(
                atPath: folder.appendingPathComponent("game/ffxiv_dx11.exe")
                    .path)
        else {
            return false
        }
        return true
    }
}
