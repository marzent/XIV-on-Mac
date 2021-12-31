//
//  Setup.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 22.12.21.
//

import Cocoa

struct Setup {
    @available(*, unavailable) private init() {}
    
    static var dep_urls = ["https://aka.ms/vs/17/release/vc_redist.x64.exe" : false,
                "https://aka.ms/vs/17/release/vc_redist.x86.exe" : false,
                "https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe" : false,
                "https://download.visualstudio.microsoft.com/download/pr/8e396c75-4d0d-41d3-aea8-848babc2736a/80b431456d8866ebe053eb8b81a168b3/NDP462-KB3151800-x86-x64-AllOS-ENU.exe" : false,
                "https://download.visualstudio.microsoft.com/download/pr/1f5af042-d0e4-4002-9c59-9ba66bcf15f6/089f837de42708daacaae7c04b7494db/NDP472-KB4054530-x86-x64-AllOS-ENU.exe" : false,
                "https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/abd170b4b0ec15ad0222a809b761a036/ndp48-x86-x64-allos-enu.exe" : false,
                "https://github.com/marzent/FFXIVQuickLauncher/releases/download/6.1.8/Setup.exe" : false]
    
    static func downloadDeps() {
        NotificationCenter.default.post(name: .installStatusUpdate, object: nil,
                                        userInfo:[Notification.status.header: "Downloading dependencies....",
                                                  Notification.status.info: "0/\(dep_urls.count) done"])
        for (url, _) in dep_urls {
            FileDownloader.loadFileAsync(url: url, onFinish: downloadDone)
        }
    }
    
    static func downloadDone(url: String) {
        dep_urls[url] = true
        let progress = dep_urls.filter({dep in return dep.value}).count
        NotificationCenter.default.post(name: .installStatusUpdate, object: nil,
                                        userInfo:[Notification.status.header: "Downloading dependencies....",
                                                  Notification.status.info: "\(progress)/\(dep_urls.count) done"])
        if dep_urls.allSatisfy({$0.value}) {
            NotificationCenter.default.post(name: .depDownloadDone, object: nil)
        }
    }
    
    static func installDeps() {
        installMSVC()
        installDotNet40()
        installDotNet462()
        installDotNet472()
        installDotNet48()
        DXVK()
        XL()
        NotificationCenter.default.post(name: .depInstallDone, object: nil)
    }
    
    static func installMSVC() {
        NotificationCenter.default.post(name: .installStatusUpdate, object: nil,
                                        userInfo:[Notification.status.header: "Installing dependencies....",
                                                  Notification.status.info: "Microsoft Visual C++ Redistributables"])
        setWine(version: "win10")
        Util.launchWine(args: [Util.cache.appendingPathComponent("vc_redist.x64.exe").path, "/install", "/passive", "/norestart"], blocking: true)
        Util.launchWine(args: [Util.cache.appendingPathComponent("vc_redist.x86.exe").path, "/install", "/passive", "/norestart"], blocking: true)
    }
    
    static func installDotNet40() {
        NotificationCenter.default.post(name: .installStatusUpdate, object: nil,
                                        userInfo:[Notification.status.header: "Installing dependencies....",
                                                  Notification.status.info: "Microsoft .NET Framework 4.0"])
        setWine(version: "winxp64")
        overideDLL(dll: "mscoree", type: "native")
        Util.launchWine(args: [Util.cache.appendingPathComponent("dotNetFx40_Full_x86_x64.exe").path, "/passive", "/norestart"], blocking: true)
        setWine(version: "win10")
    }
    
    static func installDotNet462() {
        NotificationCenter.default.post(name: .installStatusUpdate, object: nil,
                                        userInfo:[Notification.status.header: "Installing dependencies....",
                                                  Notification.status.info: "Microsoft .NET Framework 4.6.2"])
        setWine(version: "win7")
        overideDLL(dll: "mscoree", type: "native")
        Util.launchWine(args: [Util.cache.appendingPathComponent("NDP462-KB3151800-x86-x64-AllOS-ENU.exe").path, "/passive", "/norestart"], blocking: true)
        setWine(version: "win10")
    }
    
    static func installDotNet472() {
        NotificationCenter.default.post(name: .installStatusUpdate, object: nil,
                                        userInfo:[Notification.status.header: "Installing dependencies....",
                                                  Notification.status.info: "Microsoft .NET Framework 4.7.2"])
        setWine(version: "win7")
        overideDLL(dll: "mscoree", type: "native")
        Util.launchWine(args: [Util.cache.appendingPathComponent("NDP472-KB4054530-x86-x64-AllOS-ENU.exe").path, "/passive", "/norestart"], blocking: true)
        setWine(version: "win10")
    }
    
    static func installDotNet48() {
        NotificationCenter.default.post(name: .installStatusUpdate, object: nil,
                                        userInfo:[Notification.status.header: "Installing dependencies....",
                                                  Notification.status.info: "Microsoft .NET Framework 4.8"])
        setWine(version: "win10")
        overideDLL(dll: "mscoree", type: "native")
        Util.launchWine(args: [Util.cache.appendingPathComponent("ndp48-x86-x64-allos-enu.exe").path, "/passive", "/norestart"], blocking: true)
    }
    
    static func DXVK() {
        let dxvk_path = Bundle.main.url(forResource: "dxvk", withExtension: nil, subdirectory: "")!
        let dx_dlls = ["d3d9.dll", "d3d10_1.dll", "d3d10.dll", "d3d10core.dll", "dxgi.dll", "d3d11.dll"]
        let system32 = Util.prefix.appendingPathComponent("drive_c/windows/system32")
        let fm = FileManager.default
        for dll in dx_dlls {
            do {
                let dll_path = system32.appendingPathComponent(dll).path
                if fm.fileExists(atPath: dll_path) {
                    try fm.removeItem(atPath: dll_path)
                }
                try fm.copyItem(atPath: dxvk_path.appendingPathComponent(dll).path, toPath: dll_path)
                overideDLL(dll: dll.components(separatedBy: ".")[0], type: "native")
            }
            catch {
                print("error setting up dxvk dll \(dll)", to: &Util.logger)
            }
        }
    }
    
    static func XL() {
        Util.launchWine(args: [Util.cache.appendingPathComponent("Setup.exe").path])
    }
    
    static func overideDLL(dll: String, type: String) {
        Util.launchWine(args: ["reg", "add", "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides", "/v", dll, "/d", type, "/f"])
    }
    
    static func setWine(version: String) {
        Util.launchWine(args: ["winecfg", "-v", version], blocking: true)
    }
    
    
}

