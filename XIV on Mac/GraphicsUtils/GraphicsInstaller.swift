//
//  GraphicsInstaller.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 25.07.24.
//

import Foundation

enum GraphicsInstaller {
    private static let system32 = Wine.prefix.appendingPathComponent(
        "drive_c/windows/system32")

    static func install(dll: URL) {
        let dllName = dll.lastPathComponent
        Util.make(dir: system32)
        let fm = FileManager.default
        let winDllPath = system32.appendingPathComponent(dllName).path
        let oldDllPath = winDllPath + ".old"

        if !fm.contentsEqual(atPath: winDllPath, andPath: dll.path) {
            if fm.fileExists(atPath: winDllPath) {
                do {
                    if fm.fileExists(atPath: oldDllPath) {
                        try fm.removeItem(atPath: oldDllPath)
                    }
                    try fm.moveItem(atPath: winDllPath, toPath: oldDllPath)
                } catch {
                    Log.error(
                        "[GraphicsInstaller] error renaming wine dx dll \(winDllPath)\n\(error)"
                    )
                }
            }
            do {
                try fm.copyItem(atPath: dll.path, toPath: winDllPath)
            } catch {
                Log.error("[GraphicsInstaller] error copying dx dll \(error)")
            }
        }
    }

    static func restore(dllName: String) {
        let fm = FileManager.default
        let winDllPath = system32.appendingPathComponent(dllName).path
        let oldDllPath = winDllPath + ".old"

        if fm.fileExists(atPath: oldDllPath) {
            do {
                try fm.removeItem(atPath: winDllPath)
                try fm.moveItem(atPath: oldDllPath, toPath: winDllPath)
                Log.information(
                    "[GraphicsInstaller] restored old wine dx dll \(oldDllPath) to \(winDllPath)"
                )
            } catch {
                Log.error(
                    "[GraphicsInstaller] error restoring old wine dx dll \(oldDllPath)\n\(error)"
                )
            }
        }
    }

    static func ensureBackend() {
        if Settings.dxmtEnabled {
            Dxmt.install()
        } else {
            Dxvk.install()
            Dxmt.uninstall()
        }
    }
}
