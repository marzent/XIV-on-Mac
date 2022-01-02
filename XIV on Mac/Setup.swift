//
//  Setup.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 22.12.21.
//

import Cocoa
import ZIPFoundation

struct Setup {
    @available(*, unavailable) private init() {}
    
    static func postInstall(header: String) {
        NotificationCenter.default.post(name: .installStatusUpdate, object: nil,
                                        userInfo:[Notification.status.header: header,
                                                  Notification.status.info: "Installing..."])
    }
    
    static func postDownload(header: String) {
        NotificationCenter.default.post(name: .installStatusUpdate, object: nil,
                                        userInfo:[Notification.status.header: header,
                                                  Notification.status.info: "Downloading..."])
    }
    
    static func download(url: String) {
        FileDownloader.loadFileSync(url: URL(string: url)!) {(path, error) in
            print("File downloaded to : \(path!)")
        }
    }
    
    static func install(vanilla: Bool, copy: Bool, link: Bool, gamePath: String) {
        DXVK()
        vanillaConf()
        installMSVC32()
        installMSVC64()
        if copy{
            copyGame(gamePath: gamePath)
        } else if link {
            linkGame(gamePath: gamePath)
        } else if vanilla {
            vanillaLauncher()
        }
        movieFix()
        if !vanilla {
            installDotNet40()
            installDotNet462()
            installDotNet472()
            installDotNet48()
            XLConf()
            XL()
        }
        else {
            Util.launchGame()
        }
        NotificationCenter.default.post(name: .depInstallDone, object: nil)
    }
    
    static func copyGame(gamePath: String) {
        postInstall(header: "Copying Game files")
        let squex = Util.prefix.appendingPathComponent("drive_c/Program Files (x86)/SquareEnix")
        let gameDest = squex.appendingPathComponent("FINAL FANTASY XIV - A Realm Reborn")
        Util.make(dir: squex.path)
        do {
            try FileManager.default.copyItem(atPath: gamePath, toPath: gameDest.path)
        }
        catch {
            print("error copying game from \(gamePath)\n", to: &Util.logger)
        }
        Util.launchPath = Util.prefix.appendingPathComponent("drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn/boot/ffxivboot64.exe").path
    }
    
    static func linkGame(gamePath: String) {
        postInstall(header: "Linking Game files")
        let squex = Util.prefix.appendingPathComponent("drive_c/Program Files (x86)/SquareEnix")
        let gameDest = squex.appendingPathComponent("FINAL FANTASY XIV - A Realm Reborn")
        Util.make(dir: squex.path)
        do {
            try FileManager.default.createSymbolicLink(atPath: gameDest.path, withDestinationPath: gamePath)
        }
        catch {
            print("error creating symbolic link to \(gamePath)\n", to: &Util.logger)
        }
        Util.launchPath = Util.prefix.appendingPathComponent("drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn/boot/ffxivboot64.exe").path
    }
    
    static func movieFix() {
        let name = "Fixing broken ARR cutscenes"
        let version = "1.0.5"
        let movies = ["00000.bk2", "00001.bk2", "00002.bk2", "00003.bk2"]
        let moviePath = "drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn/game/movie/ffxiv"
        let unzipURL = Util.cache.appendingPathComponent("official-app")
        let appMovies = unzipURL.appendingPathComponent("FINAL FANTASY XIV ONLINE.app/Contents/SharedSupport/finalfantasyxiv/support/published_Final_Fantasy/" + moviePath)
        let prefixMovies = Util.prefix.appendingPathComponent(moviePath)
        let fm = FileManager.default
        postDownload(header: name)
        download(url: "https://mac-dl.ffxiv.com/cw/finalfantasyxiv-\(version).zip")
        postInstall(header: name)
        Util.make(dir: unzipURL.path)
        do {
            try fm.unzipItem(at: Util.cache.appendingPathComponent("finalfantasyxiv-\(version).zip"), to: unzipURL)
        }
        catch {
            print("error extracting native mac app archive\n", to: &Util.logger)
        }
        Util.make(dir: Util.prefix.appendingPathComponent(moviePath).path)
        for movie in movies {
            do {
                try fm.copyItem(atPath: appMovies.appendingPathComponent(movie).path, toPath: prefixMovies.appendingPathComponent(movie).path)
            }
            catch {
                print("error copying movie \(movie)\n", to: &Util.logger)
            }
        }
    }
    
    static func installMSVC32() {
        let name = "Microsoft Visual C++ Redistributables x86"
        postDownload(header: name)
        download(url: "https://aka.ms/vs/17/release/vc_redist.x86.exe")
        postInstall(header: name)
        setWine(version: "win10")
        Util.launchWine(args: [Util.cache.appendingPathComponent("vc_redist.x86.exe").path, "/install", "/passive", "/norestart"], blocking: true)
    }
    
    static func installMSVC64() {
        let name = "Microsoft Visual C++ Redistributables x64"
        postDownload(header: name)
        download(url: "https://aka.ms/vs/17/release/vc_redist.x64.exe")
        postInstall(header: name)
        setWine(version: "win10")
        Util.launchWine(args: [Util.cache.appendingPathComponent("vc_redist.x64.exe").path, "/install", "/passive", "/norestart"], blocking: true)
    }
    
    static func installDotNet40() {
        let name = "Microsoft .NET Framework 4.0"
        postDownload(header: name)
        download(url: "https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe")
        postInstall(header: name)
        setWine(version: "winxp64")
        overideDLL(dll: "mscoree", type: "native")
        Util.launchWine(args: [Util.cache.appendingPathComponent("dotNetFx40_Full_x86_x64.exe").path, "/passive", "/norestart"], blocking: true)
        setWine(version: "win10")
    }
    
    static func installDotNet462() {
        let name = "Microsoft .NET Framework 4.6.2"
        postDownload(header: name)
        download(url: "https://download.visualstudio.microsoft.com/download/pr/8e396c75-4d0d-41d3-aea8-848babc2736a/80b431456d8866ebe053eb8b81a168b3/NDP462-KB3151800-x86-x64-AllOS-ENU.exe")
        postInstall(header: name)
        setWine(version: "win7")
        overideDLL(dll: "mscoree", type: "native")
        Util.launchWine(args: [Util.cache.appendingPathComponent("NDP462-KB3151800-x86-x64-AllOS-ENU.exe").path, "/passive", "/norestart"], blocking: true)
        setWine(version: "win10")
    }
    
    static func installDotNet472() {
        let name = "Microsoft .NET Framework 4.7.2"
        postDownload(header: name)
        download(url: "https://download.visualstudio.microsoft.com/download/pr/1f5af042-d0e4-4002-9c59-9ba66bcf15f6/089f837de42708daacaae7c04b7494db/NDP472-KB4054530-x86-x64-AllOS-ENU.exe")
        postInstall(header: name)
        setWine(version: "win7")
        overideDLL(dll: "mscoree", type: "native")
        Util.launchWine(args: [Util.cache.appendingPathComponent("NDP472-KB4054530-x86-x64-AllOS-ENU.exe").path, "/passive", "/norestart"], blocking: true)
        setWine(version: "win10")
    }
    
    static func installDotNet48() {
        let name = "Microsoft .NET Framework 4.8"
        postDownload(header: name)
        download(url: "https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/abd170b4b0ec15ad0222a809b761a036/ndp48-x86-x64-allos-enu.exe")
        postInstall(header: name)
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
    
    static func writeConf(content: String, folder: URL, filename: String) {
        Util.make(dir: folder.path)
        let file = folder.appendingPathComponent(filename)
        do {
            if !FileManager.default.fileExists(atPath: file.path) {
                try content.write(to: file, atomically: true, encoding: String.Encoding.utf8)
            }
        } catch {
            print("Error writing \(filename)", to: &Util.logger)
        }
    }
    
    static func vanillaConf() {
        let content = "<FINAL FANTASY XIV Boot Config File>\n\n<Version>\nBrowser 1\nStartupCompleted 1"
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("My Games/FINAL FANTASY XIV - A Realm Reborn")
        writeConf(content: content, folder: folder, filename: "FFXIV_BOOT.cfg")
    }
    
    static func XLConf() {
        let content = """
{
    "PatchAcquisitionMethod": "Aria",
    "InGameAddonLoadMethod": "DllInject",
    "GamePath": "C:\\Program Files (x86)\\SquareEnix\\FINAL FANTASY XIV - A Realm Reborn",
    "IsDx11": "true",
    "InGameAddonEnabled": "true",
    "LastVersion": "6.1.8.0",
}
"""
        let folder = Util.prefix.appendingPathComponent("drive_c/users/emet-selch/Application Data/XIVLauncher")
        writeConf(content: content, folder: folder, filename: "launcherConfigV3.json")
    }
    
    static func vanillaLauncher() {
        let name = "Final Fantasy XIV - official launcher"
        postDownload(header: name)
        download(url: "https://gdl.square-enix.com/ffxiv/inst/ffxivsetup.exe")
        postInstall(header: name)
        Util.launchWine(args: [Util.cache.appendingPathComponent("ffxivsetup.exe").path], blocking: true)
        Util.launchPath = Util.prefix.appendingPathComponent("drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn/boot/ffxivboot64.exe").path
        Util.launchGame()
    }
    
    static func XL() {
        let name = "XIVLauncher"
        postDownload(header: name)
        download(url: "https://github.com/marzent/FFXIVQuickLauncher/releases/download/6.1.8/Setup.exe")
        postInstall(header: name)
        Util.launchPath = Util.prefix.appendingPathComponent("drive_c/users/emet-selch/Local Settings/Application Data/XIVLauncher/XIVLauncher.exe").path
        Util.launchWine(args: [Util.cache.appendingPathComponent("Setup.exe").path])
    }
    
    static func overideDLL(dll: String, type: String) {
        Util.launchWine(args: ["reg", "add", "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides", "/v", dll, "/d", type, "/f"])
    }
    
    static func setWine(version: String) {
        Util.launchWine(args: ["winecfg", "-v", version], blocking: true)
    }
    
    
}

