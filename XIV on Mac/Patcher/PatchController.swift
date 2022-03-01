//
//  PatchController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 26.02.22.
//

import Cocoa
import OrderedCollections

class PatchController: NSViewController {
    
    @IBOutlet private var downloadStatus: NSTextField!
    @IBOutlet private var downloadPatch: NSTextField!
    @IBOutlet private var downloadPatchStatus: NSTextField!
    @IBOutlet private var installStatus: NSTextField!
    @IBOutlet private var installPatch: NSTextField!
    @IBOutlet private var downloadBar: NSProgressIndicator!
    @IBOutlet private var downloadPatchBar: NSProgressIndicator!
    @IBOutlet private var installBar: NSProgressIndicator!
    
    let installQueue = DispatchQueue(label: "patch.installer.serial.queue", qos: .utility, attributes: [], autoreleaseFrequency: .workItem)
    
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
        DispatchQueue.global(qos: .utility).async {
            Wine.kill()
            let totalSizeMB = Patch.totalLengthMB(patches)
            self.installQueue.async {
                PatchInstaller.update()
                DispatchQueue.main.async {
                    self.installPatch.stringValue = "XIVLauncher.PatchInstaller is ready"
                }
            }
            DispatchQueue.main.async {
                self.installStatus.stringValue = "0/\(patches.count) Patches"
                self.installBar.doubleValue = 0
                self.installBar.maxValue = Double(patches.count)
            }
            for (i, patch) in patches.enumerated() {
                DispatchQueue.main.async {
                    self.downloadPatch.stringValue = patch.name
                }
                let partialSizeMB = Patch.totalLengthMB(patches[...(i - 1)])
                self.download(patch, totalSizeMB: totalSizeMB, partialSizeMB: partialSizeMB)
                DispatchQueue.main.async {
                    let downloadedMB = partialSizeMB + patch.lengthMB
                    self.downloadStatus.stringValue = "\(self.toGB(downloadedMB))/\(self.toGB(totalSizeMB)) GB"
                    self.downloadBar.doubleValue = self.downloadBar.maxValue * downloadedMB / totalSizeMB
                    self.downloadPatchBar.doubleValue = self.downloadPatchBar.maxValue
                    self.downloadPatchStatus.stringValue = "\(Int(patch.lengthMB))/\(Int(patch.lengthMB)) MB"
                }
                self.installQueue.async {
                    DispatchQueue.main.async {
                        self.installPatch.stringValue = patch.path
                    }
                    PatchInstaller.install(patch)
                    DispatchQueue.main.async {
                        let installsDone = i + 1
                        self.installBar.doubleValue = Double(installsDone)
                        self.installStatus.stringValue = "\(installsDone)/\(patches.count) Patches"
                        if installsDone == patches.count {
                            self.view.window?.close() //all done
                        }
                    }
                }
            }
        }
    }
    
    private func download(_ patch: Patch, totalSizeMB: Double, partialSizeMB: Double) {
        let headers: OrderedDictionary = [
            "User-Agent"     : FFXIVLogin.userAgentPatch,
            "Accept-Encoding": "*/*,application/metalink4+xml,application/metalink+xml",
            "Host"           : "patch-dl.ffxiv.com",
            "Connection"     : "Keep-Alive",
            "Want-Digest"    : "SHA-512;q=1, SHA-256;q=1, SHA;q=0.1"
        ]
        let destination = Patch.cache.appendingPathComponent(patch.path)
        let downloadDone = DispatchGroup()
        downloadDone.enter()
        var observation: NSKeyValueObservation?
        let task = FileDownloader.loadFileAsync(url: patch.url, headers: headers, destinationUrl: destination) { response in
            downloadDone.leave()
        }
        if let task = task {
            observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                let completedSizeMB = patch.lengthMB * progress.fractionCompleted
                let totalCompletedSizeMB = partialSizeMB + completedSizeMB
                DispatchQueue.main.async {
                    self.downloadStatus.stringValue = "\(self.toGB(totalCompletedSizeMB))/\(self.toGB(totalSizeMB)) GB"
                    self.downloadPatchStatus.stringValue = "\(Int(completedSizeMB))/\(Int(patch.lengthMB)) MB"
                    self.downloadBar.doubleValue = self.downloadBar.maxValue * totalCompletedSizeMB / totalSizeMB
                    self.downloadPatchBar.doubleValue = self.downloadPatchBar.maxValue * progress.fractionCompleted
                }
            }
            task.resume()
        }
        downloadDone.wait()
        observation?.invalidate()
    }
    
    @IBAction func quit(_ sender: Any) {
        Util.quit()
    }
 
}
