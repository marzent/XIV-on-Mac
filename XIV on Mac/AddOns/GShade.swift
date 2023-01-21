//
//  GShade.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 20.02.22.
//

import Cocoa

struct GShade {
    @available(*, unavailable) private init() {}
    
    // TODO: refactor this
    
    static func install() {
        if #available(OSX 11.0, *) {
            Util.launch(exec: URL(string: "file:///usr/bin/open")!,
                        args: ["-n", "-b", "com.apple.Terminal",
                               Bundle.main.url(forResource: "install_gshade", withExtension: "sh", subdirectory: "GShade")!.path,
                               "--env", "WINEPATH=\(Bundle.main.url(forResource: "bin", withExtension: nil, subdirectory: "wine")!.path)",
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
                               "--env", "WINEPATH=\(Bundle.main.url(forResource: "bin", withExtension: nil, subdirectory: "wine")!.path)",
                               "--env", "WINEESYNC=\(Wine.esync ? "1" : "0")",
                               "--env", "WINEPREFIX=\(Wine.prefix.path)"])
        } else {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("GSHADE_MESSAGE", comment: "")
            alert.informativeText = NSLocalizedString("GSHADE_INFORMATIVE", comment: "")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
            alert.runModal()
        }
    }
    
    static func forceUpdate() {
        if #available(OSX 11.0, *) {
            Util.launch(exec: URL(string: "file:///usr/bin/open")!,
                        args: ["-n", "-b", "com.apple.Terminal",
                               Bundle.main.url(forResource: "manual_gshade", withExtension: "sh", subdirectory: "GShade")!.path,
                               "--env", "WINEPATH=\(Bundle.main.url(forResource: "bin", withExtension: nil, subdirectory: "wine")!.path)",
                               "--env", "WINEESYNC=\(Wine.esync ? "1" : "0")",
                               "--env", "WINEPREFIX=\(Wine.prefix.path)",
                               "--env", "GSHADE_FORCE_UPDATE=1"])
        } else {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("GSHADE_MESSAGE", comment: "")
            alert.informativeText = NSLocalizedString("GSHADE_INFORMATIVE", comment: "")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
            alert.runModal()
        }
    }
}
