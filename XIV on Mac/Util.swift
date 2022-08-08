//
//  util.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 22.12.21.
//

import AppKit
import IOKit

struct Util {
    @available(*, unavailable) private init() {}
    
    static let userHome = FileManager.default.homeDirectoryForCurrentUser
    static let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last!.appendingPathComponent("XIV on Mac")
    static let cache = applicationSupport.appendingPathComponent("cache")
    static let appleReceiptsPath = URL(fileURLWithPath: "/Library/Apple/System/Library/Receipts/")
    static let seGameConfigPath = userHome.appendingPathComponent("/Documents/My Games/FINAL FANTASY XIV - A Realm Reborn/", isDirectory: true)
    
    static func make(dir : String) {
        if !FileManager.default.fileExists(atPath: dir) {
            do {
                try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                Log.error(error.localizedDescription)
            }
        }
    }
    
    static func make(dir : URL) {
        make(dir: dir.path)
    }
    
    static func removeBrokenSymlink(fileURL: URL) {
        let fm = FileManager.default
        if fm.fileExists(atPath: fileURL.path) {
            return
        }
        try? fm.removeItem(at: fileURL)
    }
    
    static func launch(exec: URL, args: [String], blocking: Bool = false) {
        let task = Process()
        task.executableURL = exec
        task.arguments = args
        do {
            try task.run()
        }
        catch {
            Log.error("Error starting subprocess")
            return
        }
        if blocking {
            task.waitUntilExit()
        }
    }
    
    static var enviroment : [String : String] {
        var env = ProcessInfo.processInfo.environment
        if Settings.platform == .steam {
            env["IS_FFXIV_LAUNCH_FROM_STEAM"] = "1"
        }
        env["LANG"] = "en_US" //needed to run when system language is set to 日本語
        env["WINEESYNC"] = Wine.esync ? "1" : "0"
        env["WINEPREFIX"] = Wine.prefix.path
        env["WINEDEBUG"] = Wine.debug
        env["WINEDLLOVERRIDES"] = "d3d9,d3d11,d3d10core,dxgi,mscoree=n"
        env["DXVK_HUD"] = Dxvk.options.getHud()
        env["DXVK_ASYNC"] = Dxvk.options.getAsync()
        env["DXVK_FRAME_RATE"] = Dxvk.options.getMaxFramerate()
        env["DXVK_STATE_CACHE_PATH"] = "C:\\"
        env["DXVK_LOG_PATH"] = "C:\\"
        env["DXVK_CONFIG_FILE"] = "C:\\ffxiv_dx11.conf"
        env["DALAMUD_RUNTIME"] = "C:\\Program Files\\XIV on Mac\\dotNET Runtime"
        env["XL_WINEONLINUX"] = "true"
        env["XL_WINEONMAC"] = "true"
        env["MVK_CONFIG_FULL_IMAGE_VIEW_SWIZZLE"] = "1"
        env["MVK_CONFIG_RESUME_LOST_DEVICE"] = "1"
        env["MVK_ALLOW_METAL_FENCES"] = "1"
        env["MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS"] = "1"
        //env["DYLD_PRINT_LIBRARIES"] = "YES"
        let mvkPath = Bundle.main.url(forResource: Dxvk.modernMVK ? "modern" : "stable", withExtension: "", subdirectory: "MoltenVK")!.path
        let winePath = Bundle.main.url(forResource: "lib", withExtension: "", subdirectory: "wine")!.path
        env["DYLD_FALLBACK_LIBRARY_PATH"] = [mvkPath, winePath, "/opt/local/lib", "/usr/local/lib", "/usr/lib", "/usr/libexec", "/usr/lib/system", "/opt/X11/lib"].joined(separator: ":")
        env["DYLD_VERSIONED_LIBRARY_PATH"] = env["DYLD_FALLBACK_LIBRARY_PATH"]
        return env
    }
    
    static func getSetting<T>(settingKey: String, defaultValue: T) -> T {
        let defaults = UserDefaults.standard
        let setting = defaults.object(forKey: settingKey)
        if setting == nil {
            defaults.set(defaultValue, forKey: settingKey)
            return defaultValue
        }
        return setting as! T
    }
    
    static func quit() {
        DispatchQueue.main.async {
            let app = NSApplication.shared
            for window in app.windows {
                window.close()
            }
            app.terminate(nil)
        }
    }
    
    static func rosettaIsInstalled() -> Bool {
        if (Util.getXOMRuntimeEnvironment() == .appleSiliconNative) {
            // Rosetta's package ID is fixed, so it's safer to check for its receipt than to look for any individual file it's known to install.
            let rosettaReceiptPath = appleReceiptsPath.appendingPathComponent("com.apple.pkg.RosettaUpdateAuto.plist");
            return (try? rosettaReceiptPath.checkResourceIsReachable()) ?? false
        }
        return false
    }
    
    static func pathExists(path: URL) -> Bool {
        var exists : Bool = false
        do {
            exists = try path.checkResourceIsReachable();
        }
        catch let error as NSError {
            if (error.domain == NSCocoaErrorDomain) && error.code == 260
            {
                // No such file, might be the first launch.
                // The default is false, this path mainly exists to document that this is the EXPECTED 'doesn't exist' error,
                // anything else should be logged/investigated.
                exists = false
            }
            else
            {
                Log.error(error.localizedDescription)
            }
        }
        return exists;
    }
    
    static private func createConfigDirectory() {
        // Do we need to create the config directory itself?
        if (!Util.pathExists(path: Settings.gameConfigPath)) {
            Log.information("Cfg: Game Config path doesn't exist.")
            // Ok, so, it may be our first launch, or our prefix was wiped etc. However, there might be an existing install from either an older XOM or
            // the SE client. See if that cfg location exists.
            if (Util.pathExists(path: seGameConfigPath))
            {
                Log.information("Cfg: Found existing game Cfg path to import.")
                // It does exist. Copy theirs to ours.
                do {
                    try FileManager.default.copyItem(at: seGameConfigPath, to: Settings.gameConfigPath)
                }
                catch let createError as NSError {
                    Log.error("Cfg: Could not import existing Cfg: \(createError.localizedDescription)")
                }

            }
            else
            {
                Log.information("Cfg: No existing game Cfg found.")
                // SE version does not exist. Just create the directory.
                do {
                    try FileManager.default.createDirectory(atPath: Settings.gameConfigPath.path, withIntermediateDirectories: true, attributes: nil)
                }
                catch let createError as NSError {
                    Log.error("Cfg: Could not create Cfg directory: \(createError.localizedDescription)")
                }
            }
        }
    }
    
    /// Attempt to load the FFXIV.cfg file (raw contents) from disk. If it does not yet exist, we attempt to create it with default values, as well as its containing folders.
    ///  - Returns: The contents of the cfg file, or nil if it cannot be read and a default could not be created.
    static func loadCfgFile() -> String? {
        var configFileContents : String? = nil
        if (!Util.pathExists(path: FFXIVApp.configURL))
        {
            createConfigDirectory();
        }
        // One way or another we should have a config folder now. IF we copied the SE one, we might also now have a .cfg file. Check again.
        if (!Util.pathExists(path: FFXIVApp.configURL))
        {
            // .cfg still doesn't exist, so let's copy in our Mac default one.
            Log.information("Cfg: No existing game configuration, establishing Mac default settings.")
            do {
                let defaultCfgURL = Bundle.main.url(forResource: "FFXIV-MacDefault", withExtension: "cfg")!
                try FileManager.default.copyItem(at: defaultCfgURL, to: FFXIVApp.configURL)
            }
            catch let createError as NSError {
                Log.error("Cfg: Could not create default Mac settings: \(createError.localizedDescription)")
            }
        }

        do {
            configFileContents = try String(contentsOf:FFXIVApp.configURL)
        }
        catch {
            Log.error(error.localizedDescription)
            return nil
        }

        return configFileContents
    }
    
    public enum XOMRuntimeEnvironment: UInt8 {
        case x64Native = 0
        case appleSiliconRosetta = 1
        case appleSiliconNative = 2
    }
    
    static func getXOMRuntimeEnvironment() -> XOMRuntimeEnvironment {
    #if arch(arm64)
        return .appleSiliconNative
    #else
        let key = "sysctl.proc_translated"
        var ret = Int32(0)
        var size: Int = 0
        sysctlbyname(key, nil, &size, nil, 0)
        let result = sysctlbyname(key, &ret, &size, nil, 0)
        if result == -1 {
            if errno == ENOENT {
                // Native process
                return .x64Native
            }
            // An error occured... Assume native?
            Log.error("Error determining execution environment")
            return .x64Native
        }
        if (ret == 1) {
            return .appleSiliconRosetta
        }
        return .x64Native
    #endif
    }
    
    static func supportedGPU() -> Bool {
        var foundSupportedGPU : Bool = false
        if (Util.getXOMRuntimeEnvironment() != .x64Native) {
            // On Apple Silicon to date, there is always a built-in GPU, and it is always supported. So we don't need to check anything.
            foundSupportedGPU = true
        }
        else {
            // On Intel, we need to find an AMD GPU. Intel iGPUs are not supported, and neither is nVidia or other oddities (USB video).
            var deviceIterator : io_iterator_t = io_iterator_t()
                                                                               
            if IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOAcceleratorClassName),&deviceIterator) == kIOReturnSuccess {
                var entry : io_registry_entry_t = IOIteratorNext(deviceIterator)
                while (entry != 0) && (!foundSupportedGPU) {
                    var properties : Unmanaged<CFMutableDictionary>? = nil
                    if IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess {
                        guard let propertiesDict = properties?.takeUnretainedValue() as? [String : AnyObject] else { continue }
                        properties?.release()
                        
                        let ioClass = propertiesDict["IOClass"]
                        if ioClass is String {
                            let ioClassString = ioClass as! String
                            if ioClassString.hasPrefix("AMDRadeon") {
                                foundSupportedGPU = true
                            }
                        }
                    }
                    
                    IOObjectRelease(entry)
                    entry = IOIteratorNext(deviceIterator)
                }
                
                IOObjectRelease(deviceIterator)
            }
        }
        return foundSupportedGPU
    }
    
}
