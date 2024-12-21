//
//  Dxmt.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 25.07.24.
//

import Foundation

struct Dxmt {
    @available(*, unavailable) private init() {}

    private static let dxmtPath = Bundle.main.url(
        forResource: "dxmt", withExtension: nil, subdirectory: "")!
    private static let d3d11Dll = dxmtPath.appendingPathComponent("d3d11.dll")
    private static let dxgiDll = dxmtPath.appendingPathComponent("dxgi.dll")

    static func install() {
        GraphicsInstaller.install(dll: d3d11Dll)
        GraphicsInstaller.install(dll: dxgiDll)
    }

    static func uninstall() {
        GraphicsInstaller.restore(dllName: dxgiDll.lastPathComponent)
    }
}
