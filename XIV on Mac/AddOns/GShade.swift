//
//  GShade.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.02.22.
//

import Cocoa

struct GShade {
    @available(*, unavailable) private init() {}
    
    static func install() {
        if #available(OSX 11.0, *) {
            Util.launch(exec: URL(string: "file:///usr/bin/open")!,
                        args: ["-n", "-b", "com.apple.Terminal",
                               Bundle.main.url(forResource: "install_gshade", withExtension: "sh", subdirectory: "GShade")!.path,
                               "--env", "WINEPATH=\( Bundle.main.url(forResource: "bin", withExtension: nil, subdirectory: "wine")!.path)",
                               "--env", "WINEESYNC=\(Wine.esync ? "1" : "0")",
                               "--env", "WINEPREFIX=\(Wine.prefix.path)"])
        } else {
            let alert = NSAlert()
            alert.messageText = "Catalina is not supported by the automatic GShade installer"
            alert.informativeText = "You can still manually run the GShade Linux install script"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    static func manual() {
        if #available(OSX 11.0, *) {
            Util.launch(exec: URL(string: "file:///usr/bin/open")!,
                        args: ["-n", "-b", "com.apple.Terminal",
                               Bundle.main.url(forResource: "manual_gshade", withExtension: "sh", subdirectory: "GShade")!.path,
                               "--env", "WINEPATH=\( Bundle.main.url(forResource: "bin", withExtension: nil, subdirectory: "wine")!.path)",
                               "--env", "WINEESYNC=\(Wine.esync ? "1" : "0")",
                               "--env", "WINEPREFIX=\(Wine.prefix.path)"])
        } else {
            let alert = NSAlert()
            alert.messageText = "When running Catalina you must have wine or CrossOver installed"
            alert.informativeText = "You can also manually add the wine version bundled with the XIV on Mac.app to your $PATH"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
}
