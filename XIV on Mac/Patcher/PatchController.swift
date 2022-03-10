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
    let formatter = ByteCountFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        formatter.allowedUnits = .useAll
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        downloadBar.usesThreadedAnimation = true
        installBar.usesThreadedAnimation = true
    }
    
    func install(_ patches: [Patch]) {
        Wine.kill()
        let totalSize = Patch.totalLength(patches)
        patchQueue.async {
            PatchInstaller.update()
            DispatchQueue.main.async { [self] in
                installPatch.stringValue = "XIVLauncher.PatchInstaller is ready"
            }
        }
        installStatus.stringValue = "0 out of \(patches.count) Patches installed"
        installBar.doubleValue = 0
        installBar.maxValue = Double(patches.count)
        for (patchNum, _) in patches.enumerated() {
            installQueue.async { [self] in
                install(patchNum: patchNum, patches: patches, totalSize: totalSize)
            }
        }
    }
    
    private func install(patchNum: Int, patches: [Patch], totalSize: Int64) {
        let patch = patches[patchNum]
        DispatchQueue.main.async { [self] in
            downloadPatch.stringValue = patch.name
        }
        let partialSize = Patch.totalLength(patches[..<patchNum])
        download(patch, totalSize: totalSize, partialSize: partialSize)
        self.updateProgress(totalCompletedSize: partialSize + patch.length, totalSize: totalSize, completedSize: patch.length, size: patch.length, speed: 0)
        patchQueue.async {
            DispatchQueue.main.async { [self] in
                installPatch.stringValue = patch.path
            }
            PatchInstaller.install(patch)
            DispatchQueue.main.async { [self] in
                let installsDone = patchNum + 1
                installBar.doubleValue = Double(installsDone)
                installStatus.stringValue = "\(installsDone) out of \(patches.count) Patches installed"
                if installsDone == patches.count {
                    view.window?.close() //all done
                }
            }
        }
    }
    
    private func download(_ patch: Patch, totalSize: Int64, partialSize: Int64, tries: Int = 0, maxTries: Int = 3) {
        let headers: OrderedDictionary = [
            "User-Agent"     : FFXIVLogin.userAgentPatch,
            "Accept-Encoding": "*/*,application/metalink4+xml,application/metalink+xml",
            "Host"           : "patch-dl.ffxiv.com",
            "Connection"     : "Keep-Alive",
            "Want-Digest"    : "SHA-512;q=1, SHA-256;q=1, SHA;q=0.1"
        ]
        let destination = Patch.cache.appendingPathComponent(patch.path)
        do {
            try HTTPClient.fetchFile(url: patch.url, destinationUrl: destination, headers: headers) { total, now, speed in
                let totalCompletedSize = partialSize + now
                self.updateProgress(totalCompletedSize: totalCompletedSize, totalSize: totalSize, completedSize: now, size: total, speed: speed)
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
            download(patch, totalSize: totalSize, partialSize: partialSize, tries: tries + 1, maxTries: maxTries)
        }
    }
    
    private func updateProgress(totalCompletedSize: Int64, totalSize: Int64, completedSize: Int64, size: Int64, speed: Int64) {
        func format(_ value: Int64) -> String {
            formatter.string(fromByteCount: value)
        }
        DispatchQueue.main.async { [self] in
            downloadStatus.stringValue = "\(format(totalCompletedSize)) of \(format(totalSize))"
            downloadPatchStatus.stringValue = "\(format(completedSize)) of \(format(size)) (\(format(speed))/sec)"
            downloadBar.doubleValue = downloadBar.maxValue * Double(totalCompletedSize) / Double(totalSize)
            downloadPatchBar.doubleValue = downloadPatchBar.maxValue * Double(completedSize) / Double(size)
        }
    }
    
    @IBAction func quit(_ sender: Any) {
        Util.quit()
    }
 
}
