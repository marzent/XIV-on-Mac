//
//  Notifications.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 26.12.21.
//

import Foundation

extension Notification.Name {
    static let depInstall = Notification.Name("DepInstallNotification")
    static let depInstallDone = Notification.Name("DepInstallDoneNotification")
    static let depDownloadDone = Notification.Name("DepDownloadDoneNotification")
}

extension Notification {
    enum dep: String {
        case name
    }
}
