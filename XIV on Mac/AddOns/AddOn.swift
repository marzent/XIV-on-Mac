//
//  AddOn.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 15.07.22.
//

struct AddOn {
    @available(*, unavailable) private init() {}

    static func launchNotify() {
        BunnyHUD.launchNotify()
    }
}
