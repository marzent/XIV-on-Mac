//
//  ScreenCapture.swift
//  XIV on Mac
//
//  Created by Chris Backas on 3/9/23.
//

import Foundation
import ScreenCaptureKit
import OSLog
import UserNotifications

public enum ScreenCaptureCodec: Int {
    case h264 = 0
    case hevc = 1
}

// A few items available prior to 13.0 to reduce the need to have availability checks everywhere
struct ScreenCaptureHelper
{
    public static var captureFolderPref : String = "ScreenCaptureDirectory"
    public static var videoCodecPref : String = "ScreenCaptureCodec"

    public static func chooseFolder() {
        let openPanel = NSOpenPanel()
        openPanel.message = NSLocalizedString("SELECT_CAPTURE_PATH_PANEL_MESSAGE", comment: "")
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = true
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.begin { response in
            if response == .OK {
                UserDefaults.standard.setValue(openPanel.url!.path, forKey: captureFolderPref)
            }
            openPanel.close()
        }
    }

}

@available(macOS 13.0, *)
class ScreenCapture {
    private let screenCaptureEngine = ScreenCaptureEngine()
    private let avWriter: AVWriter = AVWriter()
    private var isRecording: Bool = false {
        didSet {
            Task { @MainActor in
                ScreenCapture.sendScreenCaptureStatusNotification(isRecording: self.isRecording, avWriter: self.avWriter)
            }
        }
    }
    
    @MainActor
    static func sendScreenCaptureStatusNotification(isRecording: Bool, avWriter: AVWriter) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            if isRecording {
                content.title = NSLocalizedString("NOTIFY_CAPTURE_TITLE", comment: "")
                content.subtitle = NSLocalizedString("NOTIFY_CAPTURE_STARTED_SUBTITLE", comment: "")
                content.body = String(
                    format: NSLocalizedString("NOTIFY_CAPTURE_STARTED_BODY", comment: ""),
                    "\(avWriter.currentRecordingURL?.lastPathComponent ?? "")"
                )
            } else {
                content.title = NSLocalizedString("NOTIFY_CAPTURE_TITLE", comment: "")
                content.subtitle = NSLocalizedString("NOTIFY_CAPTURE_STOPPED_SUBTITLE", comment: "")
                content.body = String(
                    format: NSLocalizedString("NOTIFY_CAPTURE_STOPPED_BODY", comment: ""),
                    "\(avWriter.currentRecordingURL?.lastPathComponent ?? "")"
                )
            }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "com.marzent.XIVOnMac.ScreenCapture",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    @MainActor
    static func checkCapturePermissions() {
        Task {
            // Two permissions we need, only one of which is required.
            let recordPermission = await hasRecordPermission()
            var notifiyPermission : Bool = false

            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings { settings in
                notifiyPermission = settings.authorizationStatus == .authorized
            }

            let alert: NSAlert = .init()
            alert.messageText = NSLocalizedString("SCREEN_CAPTURE_PERMISSION", comment: "")
            if !notifiyPermission && !recordPermission
            {
                alert.informativeText = NSLocalizedString("SCREEN_CAPTURE_PERMISSION_HAVE_NONE", comment: "")
            }
            else if !notifiyPermission
            {
                alert.informativeText = NSLocalizedString("SCREEN_CAPTURE_PERMISSION_NO_NOTIFY", comment: "")
            }
            else if !recordPermission
            {
                alert.informativeText = NSLocalizedString("SCREEN_CAPTURE_PERMISSION_NO_RECORD", comment: "")
            }
            else
            {
                alert.informativeText = NSLocalizedString("SCREEN_CAPTURE_PERMISSION_HAVE_ALL", comment: "")
            }
            if (!recordPermission) {
                alert.alertStyle = .critical
            }
            else {
                alert.alertStyle = .informational
            }
            alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("SCREEN_CAPTURE_PERMISSION_OPEN_PREF_BUTTON", comment: ""))
            if !recordPermission {
                alert.icon = NSImage(named: "CfgCheckProbFailed.tiff")
            }
            else if !notifiyPermission {
                alert.icon = NSImage(named: "CfgCheckProblems.tiff")
            }
            else {
                alert.icon = NSImage(named: "CfgCheckGood.tiff")
            }
            let result = alert.runModal()
            if result == .alertSecondButtonReturn {
                if !recordPermission {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                }
                else {
                    // Should/can we just ask for permission again instead? Doesn't seem to be an exposed way to go directory to notification pane
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference")!)
                }
            }
        }
    }
    
    static func hasRecordPermission() async -> Bool {
            do {
                // If the app doesn't have Screen Recording permission, this call generates an exception.
                try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                
                return true
            } catch {
                Log.error("FFXIV Screencapture: No screen recording permissions")
                return false
            }
    }
    
    var canRecord: Bool {
        get async {
            if await !ScreenCapture.hasRecordPermission()
            {
                Log.error("FFXIV Screencapture: Can't capture, no permission!")
                return false
            }
            
            // We're single-purpose here :D
            if !FFXIVApp.running
            {
                Log.error("FFXIV Screencapture: Game is not running, nothing to capture.")
                return false
            }
                    
            return true
        }
    }
    
    func toggleScreenCapture()
    {
        if (isRecording)
        {
            stopCapture()
        }
        else
        {
            startCapture()
        }
    }
    
    func startCapture()
    {
        Task {
            if await canRecord {
                await doStartCapture()
            }
        }
    }
    
    func stopCapture()
    {
        Task {
            await screenCaptureEngine.stopCapture()
            await MainActor.run{
                isRecording = false
            }
        }
    }
    
    private func filterWindows(_ windows: [SCWindow]) -> [SCWindow] {
        //let gamePids : [pid_t] = Wine.pidsOf(processName: "ffxiv_dx11.exe")
        return windows
        // Would be BEST to use the pids from above to identify  the process properly, but that's returning Windows PIDs and
        // currently I don't know how to map them to macOS pids. So we use a hacky filter for now...
            .filter { $0.owningApplication?.applicationName ?? "" == "wine64-preloader" }
            .filter { $0.title ?? "" == "FINAL FANTASY XIV" }
        // We don't really expect more than 1, but just in case let's make the result stable
            .sorted { $0.owningApplication?.processID ?? 0 < $1.owningApplication?.processID ?? 0 }
    }

    
    private func refreshAvailableContent() async -> SCWindow? {
        do {
            // Retrieve the available screen content to capture.
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false,
                                                                                        onScreenWindowsOnly: true)
            let windows = filterWindows(availableContent.windows)

            return windows.first
            
        } catch {
            Log.error("FFXIV Screencapture: Failed to get the shareable content: \(error.localizedDescription)")
        }
        return nil
    }

    private func streamConfiguration(forWindow:SCWindow) -> SCStreamConfiguration {
        let streamConfig = SCStreamConfiguration()
        
        // Configure audio capture.
        streamConfig.capturesAudio = true
        streamConfig.excludesCurrentProcessAudio = true
        streamConfig.showsCursor = false // Hide mouse
        
        // Configure the window content width and height.
        streamConfig.width = Int(forWindow.frame.width) * 2
        streamConfig.height = Int(forWindow.frame.height) * 2
        
        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 5
        
        return streamConfig
    }

    
    func doStartCapture() async
    {
        guard let window : SCWindow = await refreshAvailableContent() else
        {
            Log.error("FFXIV Screencapture: No game windows found to capture")
            return
        }
        
        let filter = SCContentFilter(desktopIndependentWindow: window)
        screenCaptureEngine.avWriter = self.avWriter
        screenCaptureEngine.startCapture(configuration: streamConfiguration(forWindow: window), filter: filter)
        await MainActor.run{
            isRecording = true
        }
    }
    
}
