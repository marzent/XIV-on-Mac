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

private struct RepairProgress: Codable {
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

class RepairController: ObservableObject {
    @Published var repairStatus : String = ""
    @Published var currentFile : String = ""
    @Published var repairProgress : Double = 0.0
    @Published var repairProgressMax : Double = 100.0
    @Published var repairing : Bool = false

    private var timer: Timer?
    let formatter = ByteCountFormatter()
    
    func repair(_ loginResult: LoginResult) {
        DispatchQueue.main.async { [self] in
            self.repairing = false
        }
        DispatchQueue.global(qos: .userInitiated).async {
            Wine.kill()
            DispatchQueue.main.async { [self] in
                self.repairing = true
                let updateInterval = 0.25
                timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
                    self.updateProgress()
                }
            }
            let repairResult = loginResult.repairGame()
            DispatchQueue.main.async { [self] in
                timer?.invalidate()
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
            // TODO: We can probably do all this in an init once this isn't an NSViewController anymore...
            formatter.allowedUnits = .useAll
            formatter.countStyle = .file
            formatter.includesUnit = true
            formatter.isAdaptive = true

            repairStatus = repairProgress.currentStep + " (\(formatter.string(fromByteCount: repairProgress.speed))/sec)"
            currentFile = repairProgress.currentFile
            self.repairProgress = Double(repairProgress.progress)
            self.repairProgressMax = Double(repairProgress.total)
        }
    }
    
    func quit(_ sender: Any) {
        Util.quit()
    }
}
