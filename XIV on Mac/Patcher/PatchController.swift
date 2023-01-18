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
    
    static var isPatching = DispatchSemaphore(value: 0)
    
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
        // Wine.kill()
        let totalSize = Patch.totalLength(patches)
        DispatchQueue.main.async { [self] in
            installPatch.stringValue = NSLocalizedString("PATCH_INSTALLATION_WAITING", comment: "")
            installStatus.stringValue = String(format: NSLocalizedString("PATCH_INSTALLATION_PROGRESS_INIT", comment: ""), patches.count)
            installBar.doubleValue = 0
            installBar.maxValue = Double(patches.count)
        }
        for (patchNum, _) in patches.enumerated() {
            installQueue.async { [self] in
                install(patchNum: patchNum, patches: patches, totalSize: totalSize)
            }
        }
        PatchController.isPatching.wait()
    }
    
    private func install(patchNum: Int, patches: [Patch], totalSize: Int64) {
        let patch = patches[patchNum]
        DispatchQueue.main.async { [self] in
            downloadPatch.stringValue = patch.name
        }
        let partialSize = Patch.totalLength(patches[..<patchNum])
        download(patch, totalSize: totalSize, partialSize: partialSize)
        updateProgress(totalCompletedSize: partialSize + patch.length, totalSize: totalSize, completedSize: patch.length, size: patch.length, speed: 0)
        patchQueue.async {
            DispatchQueue.main.async { [self] in
                installPatch.stringValue = patch.path
            }
            patch.install()
            DispatchQueue.main.async { [self] in
                let installsDone = patchNum + 1
                installBar.doubleValue = Double(installsDone)
                installStatus.stringValue = String(format: NSLocalizedString("PATCH_INSTALLATION_PROGRESS", comment: ""), installsDone, patches.count)
                if installsDone == patches.count {
                    FFXIVRepo.verToBck()
                    PatchController.isPatching.signal()
                    view.window?.close() // all done
                }
            }
        }
    }
    
    private func download(_ patch: Patch, totalSize: Int64, partialSize: Int64, tries: Int = 0, maxTries: Int = 3) {
        let headers: OrderedDictionary = [
            "User-Agent": Patch.userAgent,
            "Accept-Encoding": "*/*,application/metalink4+xml,application/metalink+xml",
            "Host": "patch-dl.ffxiv.com",
            "Connection": "Keep-Alive",
            "Want-Digest": "SHA-512;q=1, SHA-256;q=1, SHA;q=0.1"
        ]
        let destination = Patch.dir.appendingPathComponent(patch.path)
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
                    alert.addButton(withTitle: NSLocalizedString("PATCH_INSTALLATION_ERROR_BUTTON", comment: ""))
                    alert.alertStyle = .critical
                    alert.messageText = NSLocalizedString("PATCH_INSTALLATION_ERROR_MESSAGE", comment: "")
                    alert.informativeText = String(format: NSLocalizedString("PATCH_INSTALLATION_ERROR_INFORMATIVE", comment: ""), patch.url.absoluteString, maxTries)
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
            downloadStatus.stringValue = String(format: NSLocalizedString("PATCH_INSTALLATION_DOWNLOAD_STATUS", comment: ""), format(totalCompletedSize), format(totalSize))
            downloadPatchStatus.stringValue = String(format: NSLocalizedString("PATCH_INSTALLATION_DOWNLOAD_STATUS_PATCH", comment: ""), format(completedSize), format(size), format(speed))
            downloadBar.doubleValue = downloadBar.maxValue * Double(totalCompletedSize) / Double(totalSize)
            downloadPatchBar.doubleValue = downloadPatchBar.maxValue * Double(completedSize) / Double(size)
        }
    }
    
    @IBAction func quit(_ sender: Any) {
        Util.quit()
    }
}
