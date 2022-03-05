//
//  PatchController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 26.02.22.
//

import Cocoa
import OrderedCollections
import SeeURL

class PatchController: NSViewController {
    
    @IBOutlet private var downloadStatus: NSTextField!
    @IBOutlet private var downloadPatch: NSTextField!
    @IBOutlet private var downloadPatchStatus: NSTextField!
    @IBOutlet private var installStatus: NSTextField!
    @IBOutlet private var installPatch: NSTextField!
    @IBOutlet private var downloadBar: NSProgressIndicator!
    @IBOutlet private var downloadPatchBar: NSProgressIndicator!
    @IBOutlet private var installBar: NSProgressIndicator!
    
    let installQueue = DispatchQueue(label: "installer.serial.queue", qos: .utility, attributes: [], autoreleaseFrequency: .workItem)
    let patchQueue = DispatchQueue(label: "patch.installer.serial.queue", qos: .utility, attributes: [], autoreleaseFrequency: .workItem)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        downloadBar.usesThreadedAnimation = true
        installBar.usesThreadedAnimation = true
    }
    
    private func toGB(_ number: Double) -> Double {
        return Double(round(number * 0.1) / 100)
    }
    
    func install(_ patches: [Patch]) {
        Wine.kill()
        let totalSizeMB = Patch.totalLengthMB(patches)
        patchQueue.async {
            PatchInstaller.update()
            DispatchQueue.main.async { [self] in
                installPatch.stringValue = "XIVLauncher.PatchInstaller is ready"
            }
        }
        installStatus.stringValue = "0/\(patches.count) Patches"
        installBar.doubleValue = 0
        installBar.maxValue = Double(patches.count)
        for (patchNum, _) in patches.enumerated() {
            installQueue.async { [self] in
                install(patchNum: patchNum, patches: patches, totalSizeMB: totalSizeMB)
            }
        }
    }
    
    private func install(patchNum: Int, patches: [Patch], totalSizeMB: Double) {
        let patch = patches[patchNum]
        DispatchQueue.main.async { [self] in
            downloadPatch.stringValue = patch.name
        }
        let partialSizeMB = Patch.totalLengthMB(patches[...(patchNum - 1)])
        download(patch, totalSizeMB: totalSizeMB, partialSizeMB: partialSizeMB)
        DispatchQueue.main.async { [self] in
            let downloadedMB = partialSizeMB + patch.lengthMB
            downloadStatus.stringValue = "\(toGB(downloadedMB))/\(toGB(totalSizeMB)) GB"
            downloadBar.doubleValue = downloadBar.maxValue * downloadedMB / totalSizeMB
            downloadPatchBar.doubleValue = downloadPatchBar.maxValue
            downloadPatchStatus.stringValue = "\(Int(patch.lengthMB))/\(Int(patch.lengthMB)) MB"
        }
        patchQueue.async {
            DispatchQueue.main.async { [self] in
                installPatch.stringValue = patch.path
            }
            PatchInstaller.install(patch)
            DispatchQueue.main.async { [self] in
                let installsDone = patchNum + 1
                installBar.doubleValue = Double(installsDone)
                installStatus.stringValue = "\(installsDone)/\(patches.count) Patches"
                if installsDone == patches.count {
                    view.window?.close() //all done
                }
            }
        }
    }
    
    private func download(_ patch: Patch, totalSizeMB: Double, partialSizeMB: Double, tries: Int = 0, maxTries: Int = 3) {
        let headers: OrderedDictionary = [
            "User-Agent"     : FFXIVLogin.userAgentPatch,
            "Accept-Encoding": "*/*,application/metalink4+xml,application/metalink+xml",
            "Host"           : "patch-dl.ffxiv.com",
            "Connection"     : "Keep-Alive",
            "Want-Digest"    : "SHA-512;q=1, SHA-256;q=1, SHA;q=0.1"
        ]
        let destination = Patch.cache.appendingPathComponent(patch.path)
        do {
            try HTTPClient.fetchFile(url: patch.url, destinationUrl: destination, headers: headers) { total, now in
                let completedSizeMB = patch.lengthMB * (now/total)
                let totalCompletedSizeMB = partialSizeMB + completedSizeMB
                DispatchQueue.main.async { [self] in
                    downloadStatus.stringValue = "\(toGB(totalCompletedSizeMB))/\(toGB(totalSizeMB)) GB"
                    downloadPatchStatus.stringValue = "\(Int(completedSizeMB))/\(Int(patch.lengthMB)) MB"
                    downloadBar.doubleValue = downloadBar.maxValue * totalCompletedSizeMB / totalSizeMB
                    downloadPatchBar.doubleValue = downloadPatchBar.maxValue * (now/total)
                }
            }
        }
        catch {
            guard tries < maxTries else {
                DispatchQueue.main.sync {
                    let alert = NSAlert()
                    alert.addButton(withTitle: "Close")
                    alert.alertStyle = .critical
                    alert.messageText = "Download Error"
                    alert.informativeText = "XIV on Mac could not download \(patch.url) after \(maxTries) attempts"
                    alert.runModal()
                    Util.quit()
                }
                return
            }
            download(patch, totalSizeMB: totalSizeMB, partialSizeMB: partialSizeMB, tries: tries + 1, maxTries: maxTries)
        }
    }
    
    @IBAction func quit(_ sender: Any) {
        Util.quit()
    }
 
}
