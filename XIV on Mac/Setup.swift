//
//  Setup.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 22.12.21.
//

import Cocoa

struct Setup {
    @available(*, unavailable) private init() {}
    
    static func downloadDeps() {
        FileDownloader.loadFileAsync(url: URL(string: "https://aka.ms/vs/17/release/vc_redist.x64.exe")!)
        FileDownloader.loadFileAsync(url: URL(string: "https://aka.ms/vs/17/release/vc_redist.x86.exe")!)
        FileDownloader.loadFileAsync(url: URL(string: "https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe")!)
        FileDownloader.loadFileAsync(url: URL(string: "https://download.visualstudio.microsoft.com/download/pr/8e396c75-4d0d-41d3-aea8-848babc2736a/80b431456d8866ebe053eb8b81a168b3/NDP462-KB3151800-x86-x64-AllOS-ENU.exe")!)
        FileDownloader.loadFileAsync(url: URL(string: "https://download.visualstudio.microsoft.com/download/pr/1f5af042-d0e4-4002-9c59-9ba66bcf15f6/089f837de42708daacaae7c04b7494db/NDP472-KB4054530-x86-x64-AllOS-ENU.exe")!)
        FileDownloader.loadFileAsync(url: URL(string: "https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/abd170b4b0ec15ad0222a809b761a036/ndp48-x86-x64-allos-enu.exe")!)
    }
    
    static func overideDLL(dll: String, type: String) {
        Util.launchWine(args: ["reg", "add", "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides", "/v", dll, "/d", type, "/f"], logger: nil)
    }
}

