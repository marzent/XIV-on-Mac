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

    static func documentsFolderWritable() -> Bool {
        var writable : Bool = false
        // We're trying to check for TCC write permissions here, but there's no API (as far as I know) to test this. So, we're using "can we write something"
        // as a reasonable proxy. Since, if we can't it sorta doesn't matter if the reason is actually TCC or not - things won't work just the same!
        
        // If we can load the cfg file, we have read permission which PROBABLY means we're good from a TCC POV as it doesn't distinguish read vs write.
        // Bonus, the loadCfgFile() method will handle creating the folder and a default cfg for us if need be.
        // If this call returns nil, then we definitely don't have the permission we need.
        if (loadCfgFile() != nil)
        {
            // However, the game *requires* write, so let's check for it explicitly.
            let writeTestURL : URL = FFXIVApp.configFolder.appendingPathComponent("WritabilityTest")
            do {
                try "Writability Test, feel free to delete".write(to: writeTestURL, atomically: true, encoding: .utf8)
                try FileManager.default.removeItem(at: writeTestURL)
                // If we get here, we seem to be good!
                writable = true
            }
            catch {
                // Write failed
                Log.error(error.localizedDescription)
            }
        }
        
        return writable
    }
    
    /// Attempt to load the FFXIV.cfg file (raw contents) from disk. If it does not yet exist, we attempt to create it with default values, as well as its containing folders.
    ///  - Returns: The contents of the cfg file, or nil if it cannot be read and a default could not be created.
    static func loadCfgFile() -> String? {
        var configFileContents : String? = nil
        var tryCreate = false
        do {
            tryCreate = try !FFXIVApp.configURL.checkResourceIsReachable()
        }
        catch let error as NSError {
            if (error.domain == NSCocoaErrorDomain) && error.code == 260
            {
                // No such file, might be the first launch.
                tryCreate = true
            }
            else
            {
                Log.error(error.localizedDescription)
                return nil
            }
        }
        if (tryCreate)
        {
            do {
                try FileManager.default.createDirectory(atPath: FFXIVApp.configFolder.path, withIntermediateDirectories: true, attributes: nil)
                let defaultCfgURL = Bundle.main.url(forResource: "FFXIV-MacDefault", withExtension: "cfg")!
                try FileManager.default.copyItem(at: defaultCfgURL, to: FFXIVApp.configURL)
            }
            catch let createError as NSError {
                Log.error(createError.localizedDescription)
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
