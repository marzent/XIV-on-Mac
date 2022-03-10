//
//  util.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 22.12.21.
//

import Cocoa
import CryptoSwift

struct Util {
    @available(*, unavailable) private init() {}
    
    static let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last!.appendingPathComponent("XIV on Mac")
    static let cache = applicationSupport.appendingPathComponent("cache")
    static let appleReceiptsPath = URL(fileURLWithPath: "/Library/Apple/System/Library/Receipts/")

    class Log: TextOutputStream {
        var logName: String
        
        init(name: String) {
            logName = name
        }
        
        func write(_ string: String) {
            if (string == "\n" || string == "") {
                return
            }
            let log = applicationSupport.appendingPathComponent(logName)
            if let handle = try? FileHandle(forWritingTo: log) {
                handle.seekToEndOfFile()
                handle.write(string.data(using: .utf8)!)
                handle.closeFile()
            } else {
                try? string.data(using: .utf8)?.write(to: log)
            }
        }
    }

    static var logger = Log(name: "app.log")
    
    static func make(dir : String) {
        if !FileManager.default.fileExists(atPath: dir) {
            do {
                try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    static func make(dir : URL) {
        make(dir: dir.path)
    }
    
    static func launch(exec: URL, args: [String], blocking: Bool = false) {
        let task = Process()
        task.qualityOfService = QualityOfService.userInteractive
        task.environment = enviroment
        task.executableURL = exec
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                print(line, to: &Wine.logger)
            } else {
                print("Error decoding data: \(pipe.availableData)\n", to: &logger)
            }
        }
        do {
            try task.run()
        }
        catch {
            print("Error starting subprocess", to: &logger)
        }
        if blocking {
            task.waitUntilExit()
        }
    }
    
    static func launchToString(exec: URL, args: [String]) -> String {
        var ret = ""
        let task = Process()
        task.qualityOfService = QualityOfService.userInteractive
        task.environment = enviroment
        task.executableURL = exec
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                ret.append(contentsOf: line)
            } else {
                print("Error decoding data: \(pipe.availableData)\n", to: &logger)
            }
        }
        do {
            try task.run()
        }
        catch {
            print("Error starting subprocess", to: &logger)
        }
        task.waitUntilExit()
        return ret
    }
    
    static var enviroment : [String : String] {
        var env = ProcessInfo.processInfo.environment
        if FFXIVSettings.platform == .steam {
            env["IS_FFXIV_LAUNCH_FROM_STEAM"] = "1"
        }
        env["LANG"] = "en_US" //needed to run when system language is set to 日本語
        env["WINEESYNC"] = Wine.esync ? "1" : "0"
        env["WINEPREFIX"] = Wine.prefix.path
        env["WINEDEBUG"] = Wine.debug
        env["DXVK_HUD"] = DXVK.options.getHud()
        env["DXVK_ASYNC"] = DXVK.options.getAsync()
        env["DXVK_FRAME_RATE"] = DXVK.options.getMaxFramerate()
        env["DALAMUD_RUNTIME"] = "C:\\Program Files\\XIV on Mac\\dotNET Runtime"
        env["XL_WINEONLINUX"] = "true"
        env["XL_WINEONMAC"] = "true"
        env["MVK_CONFIG_FULL_IMAGE_VIEW_SWIZZLE"] = "1"
        env["MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS"] = "1"
        //env["DYLD_PRINT_LIBRARIES"] = "YES"
        env["DYLD_FALLBACK_LIBRARY_PATH"] = Bundle.main.url(forResource: "lib", withExtension: "", subdirectory: "wine")!.path + ":/opt/local/lib:/usr/local/lib:/usr/lib:/usr/libexec:/usr/lib/system:/opt/X11/lib"
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
    
    static func zeroPadArray(array: [UInt8]) -> [UInt8] {
        let zeroes = Blowfish.blockSize - (array.count % Blowfish.blockSize)
        if zeroes > 0 {
            return array + [UInt8](repeating: 0, count: zeroes)
        }
        return array
    }
    
    static func swapByteOrder32(_ bytes: [UInt8]) -> [UInt8]{
        var mbytes = bytes
        for i in stride(from: 0, to: bytes.count, by: 4) {
            for j in 0 ..< 4 {
                mbytes[i + j] = bytes[i + 3 - j]
            }
        }
        return mbytes
    }
    
    static func quit() {
        let app = NSApplication.shared
        for window in app.windows {
            window.close()
        }
        app.terminate(nil)
    }
    
    static func rosettaIsInstalled() -> Bool {
    #if arch(arm64)
        // Rosetta's package ID is fixed, so it's safer to check for its receipt than to look for any individual file it's known to install.
        let rosettaReceiptPath = appleReceiptsPath.appendingPathComponent("com.apple.pkg.RosettaUpdateAuto.plist");
        do{
            let receiptExists : Bool = try rosettaReceiptPath.checkResourceIsReachable()
            return receiptExists
        }catch{
        }
    #endif
        return false
    }
}
