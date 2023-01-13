//
//  Dotnet.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 22.12.21.
//

import Cocoa
import ZIPFoundation
import SeeURL

struct Dotnet {
    @available(*, unavailable) private init() {}
    
    static func download(url: String) {
        try? HTTPClient.fetchFile(url: URL(string: url)!)
    }

    static func install() {
        installMSVC32()
        installMSVC64()
        installDotNet40()
        installDotNet462()
        installDotNet472()
        installDotNet48()
    }
    
    static func installMSVC32() {
        download(url: "https://aka.ms/vs/17/release/vc_redist.x86.exe")
        Wine.set(version: "win10")
        Wine.launch(command: "\"\(Util.cache.appendingPathComponent("vc_redist.x86.exe").path)\" /install /passive /norestart", blocking: true)
    }
    
    static func installMSVC64() {
        download(url: "https://aka.ms/vs/17/release/vc_redist.x64.exe")
        Wine.set(version: "win10")
        Wine.launch(command: "\"\(Util.cache.appendingPathComponent("vc_redist.x64.exe").path)\" /install /passive /norestart", blocking: true)
    }
    
    static func installDotNet40() {
        download(url: "https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe")
        Wine.set(version: "winxp64")
        Wine.launch(command: "\"\(Util.cache.appendingPathComponent("dotNetFx40_Full_x86_x64.exe").path)\" /passive /norestart", blocking: true)
        Wine.set(version: "win10")
    }
    
    static func installDotNet462() {
        download(url: "https://download.visualstudio.microsoft.com/download/pr/8e396c75-4d0d-41d3-aea8-848babc2736a/80b431456d8866ebe053eb8b81a168b3/NDP462-KB3151800-x86-x64-AllOS-ENU.exe")
        Wine.set(version: "win7")
        Wine.launch(command: "\"\(Util.cache.appendingPathComponent("NDP462-KB3151800-x86-x64-AllOS-ENU.exe").path)\" /passive /norestart", blocking: true)
        Wine.set(version: "win10")
    }
    
    static func installDotNet472() {
        download(url: "https://download.visualstudio.microsoft.com/download/pr/1f5af042-d0e4-4002-9c59-9ba66bcf15f6/089f837de42708daacaae7c04b7494db/NDP472-KB4054530-x86-x64-AllOS-ENU.exe")
        Wine.set(version: "win7")
        Wine.launch(command: "\"\(Util.cache.appendingPathComponent("NDP472-KB4054530-x86-x64-AllOS-ENU.exe").path)\" /passive /norestart", blocking: true)
        Wine.set(version: "win10")
    }
    
    static func installDotNet48() {
        download(url: "https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/abd170b4b0ec15ad0222a809b761a036/ndp48-x86-x64-allos-enu.exe")
        Wine.set(version: "win10")
        Wine.launch(command: "\"\(Util.cache.appendingPathComponent("ndp48-x86-x64-allos-enu.exe").path)\" /passive /norestart", blocking: true)
    }
    
    static func installDotNet607() {
        download(url: "https://download.visualstudio.microsoft.com/download/pr/dc0e0e83-0115-4518-8b6a-590ed594f38a/65b63e41f6a80decb37fa3c5af79a53d/windowsdesktop-runtime-6.0.7-win-x64.exe")
        Wine.set(version: "win10")
        Wine.launch(command: "\"\(Util.cache.appendingPathComponent("windowsdesktop-runtime-6.0.7-win-x64.exe").path)\"", blocking: true)
    }
    
    static func installAspDotNet607() {
        download(url: "https://download.visualstudio.microsoft.com/download/pr/c4c86d02-a47b-4bd4-b73d-ec3be19e5245/76c673e22a120464c95f85bef342a361/aspnetcore-runtime-6.0.7-win-x64.exe")
        Wine.set(version: "win10")
        Wine.launch(command: "\"\(Util.cache.appendingPathComponent("aspnetcore-runtime-6.0.7-win-x64.exe").path)\"", blocking: true)
    }
    
    static func installDotNet702() {
        download(url: "https://download.visualstudio.microsoft.com/download/pr/8d4ae76c-10d6-450c-b1c2-76b7b2156dc3/9207c5d5d0b608d8ec0622efa4419ed6/windowsdesktop-runtime-7.0.2-win-x64.exe")
        Wine.set(version: "win10")
        Wine.launch(command: "\"\(Util.cache.appendingPathComponent("windowsdesktop-runtime-7.0.2-win-x64.exe").path)\"", blocking: true)
    }
    
}

