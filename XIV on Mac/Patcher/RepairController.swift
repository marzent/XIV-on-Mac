//
//  RepairController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 27.05.22.
//

import Cocoa
import OrderedCollections
import XIVLauncher

// MARK: - RepairProgress
fileprivate struct RepairProgress: Codable {
    let currentStep, currentFile: String
    let total, progress, speed: Int64

    enum CodingKeys: String, CodingKey {
        case currentStep = "CurrentStep"
        case currentFile = "CurrentFile"
        case total = "Total"
        case progress = "Progress"
        case speed = "Speed"
    }
    
    init() throws {
        let repairCString = queryRepairProgress()!
        let repairProgressJSON = String(cString: repairCString)
        free(UnsafeMutableRawPointer(mutating: repairCString))
        do {
            self = try JSONDecoder().decode(RepairProgress.self, from: repairProgressJSON.data(using: .utf8)!)
        }
        catch {
            throw XLError.runtimeError(repairProgressJSON).tryMap
        }
    }
}


class RepairController: NSViewController {
    
    @IBOutlet private var repairStatus: NSTextField!
    @IBOutlet private var currentFile: NSTextField!
    @IBOutlet private var repairBar: NSProgressIndicator!
    
    private var timer: Timer?
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
        repairBar.usesThreadedAnimation = true
        updateProgress()
    }
    
    func repair(_ loginResult: LoginResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            Wine.kill()
            DispatchQueue.main.async { [self] in
                let updateInterval = 0.25
                timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
                    self.updateProgress()
                }
            }
            let repairResult = loginResult.repairGame()
            DispatchQueue.main.async { [self] in
                timer?.invalidate()
                view.window?.close()
                let alert = NSAlert()
                alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
                alert.alertStyle = .critical
                alert.messageText = NSLocalizedString("REPAIR_RESULT", comment: "")
                alert.informativeText = repairResult
                alert.runModal()
            }
        }
    }
    
    private func updateProgress() {
        guard let repairProgress = try? RepairProgress() else {
            return
        }
        DispatchQueue.main.async { [self] in
            repairStatus.stringValue = repairProgress.currentStep + " (\(formatter.string(fromByteCount: repairProgress.speed))/sec)"
            currentFile.stringValue = repairProgress.currentFile
            repairBar.doubleValue = Double(repairProgress.progress)
            repairBar.maxValue = Double(repairProgress.total)
        }
    }
    
    @IBAction func quit(_ sender: Any) {
        Util.quit()
    }
}
