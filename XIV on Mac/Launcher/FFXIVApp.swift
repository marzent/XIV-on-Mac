//
//  FFXIVApp.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 17.03.22.
//

import Foundation

public struct FFXIVApp {
    static let configURL = Settings.gameConfigPath.appendingPathComponent("FFXIV.cfg")
    let bootRepoURL, bootExeURL, bootExe64URL, launcherExeURL, launcherExe64URL, updaterExeURL, updaterExe64URL: URL
    let gameRepoURL, dx9URL, dx11URL, sqpackFolderURL: URL
    private let bootFiles: [URL]
    private let movieFiles: [URL]
    
    init() {
        bootRepoURL = Settings.gamePath.appendingPathComponent("boot")
        bootExeURL = bootRepoURL.appendingPathComponent("ffxivboot.exe")
        bootExe64URL = bootRepoURL.appendingPathComponent("ffxivboot64.exe")
        launcherExeURL = bootRepoURL.appendingPathComponent("ffxivlauncher.exe")
        launcherExe64URL = bootRepoURL.appendingPathComponent("ffxivlauncher64.exe")
        updaterExeURL = bootRepoURL.appendingPathComponent("ffxivupdater.exe")
        updaterExe64URL = bootRepoURL.appendingPathComponent("ffxivupdater64.exe")
        
        gameRepoURL = Settings.gamePath.appendingPathComponent("game")
        dx9URL = gameRepoURL.appendingPathComponent("ffxiv.exe")
        dx11URL = gameRepoURL.appendingPathComponent("ffxiv_dx11.exe")
        sqpackFolderURL = gameRepoURL.appendingPathComponent("sqpack")
        
        bootFiles = [bootExeURL, bootExe64URL, launcherExeURL, launcherExe64URL, updaterExeURL, updaterExe64URL]
        
        let arrMovieFolder = gameRepoURL.appendingPathComponent("movie/ffxiv")
        movieFiles = ["00000.bk2", "00001.bk2", "00002.bk2", "00003.bk2"].map
            {arrMovieFolder.appendingPathComponent($0)}
    }
    
    static var running: Bool {
        instances > 0
    }
    
    static var instances: Int {
        Wine.pidsOf(processName: "ffxiv_dx11.exe").count
    }
    
    var installed: Bool {
        (bootFiles + movieFiles).allSatisfy({FileManager.default.fileExists(atPath: $0.path)})
    }
}
