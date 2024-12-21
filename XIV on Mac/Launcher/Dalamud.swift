//
//  Dalamud.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 10.02.23.
//

import Foundation

enum Dalamud {
    enum InstallState: UInt8 {
        case ok
        case failed
        case outOfDate
    }

    enum LoadMethod: UInt8 {
        case entryPoint
        case dllInject
        case ACLonly
    }
}
