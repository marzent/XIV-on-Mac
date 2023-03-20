//
//  util.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 22.12.21.
//

import AppKit
import IOKit
import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleVideoCapture = Self("toggleVideoCapture")
}

struct Util {
    @available(*, unavailable) private init() {}
    
    static let userHome = FileManager.default.homeDirectoryForCurrentUser
    static let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last!.appendingPathComponent("XIV on Mac")
    static let cache = applicationSupport.appendingPathComponent("cache")
    
    static func make(dir: String) {
        if !FileManager.default.fileExists(atPath: dir) {
            do {
                try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                Log.error(error.localizedDescription)
            }
        }
    }
    
    static func make(dir: URL) {
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
    
    static func pathExists(path: URL) -> Bool {
        var exists = false
        do {
            exists = try path.checkResourceIsReachable()
        }
        catch let error as NSError {
            if (error.domain == NSCocoaErrorDomain) && error.code == 260 {
                // No such file, might be the first launch.
                // The default is false, this path mainly exists to document that this is the EXPECTED 'doesn't exist' error,
                // anything else should be logged/investigated.
                exists = false
            }
            else {
                Log.error(error.localizedDescription)
            }
        }
        return exists
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
        var size = 0
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
        if ret == 1 {
            return .appleSiliconRosetta
        }
        return .x64Native
#endif
    }
    
    static func supportedGPU() -> Bool {
        var foundSupportedGPU = false
        if Util.getXOMRuntimeEnvironment() != .x64Native {
            // On Apple Silicon to date, there is always a built-in GPU, and it is always supported. So we don't need to check anything.
            foundSupportedGPU = true
        }
        else {
            // On Intel, we need to find an AMD GPU. Intel iGPUs are not supported, and neither is nVidia or other oddities (USB video).
            var deviceIterator = io_iterator_t()
            
            if IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOAcceleratorClassName), &deviceIterator) == kIOReturnSuccess {
                var entry: io_registry_entry_t = IOIteratorNext(deviceIterator)
                while (entry != 0) && !foundSupportedGPU {
                    var properties: Unmanaged<CFMutableDictionary>?
                    if IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess {
                        guard let propertiesDict = properties?.takeUnretainedValue() as? [String: AnyObject] else { continue }
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

extension View {
    func createNewWindow(title: String, delegate: NSWindowDelegate?, geometry: NSRect = NSRect(x: 20, y: 20, width: 640, height: 500), style: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]) -> NSWindow
    {
        let window = NSWindow(contentRect: geometry, styleMask: style, backing: .buffered, defer: false)
        window.center()
        window.isReleasedWhenClosed = false
        window.title = title
        window.delegate = delegate
        window.contentView = NSHostingView(rootView: self)
        return window
    }
}
