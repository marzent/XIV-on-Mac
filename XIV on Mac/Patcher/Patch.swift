//
//  Patch.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 25.02.22.
//

import AppKit
import XIVLauncher

public struct Patch: Codable {
    let version, hashType: String
    private let _url: String
    let hashBlockSize: Int
    let hashes: [String]?
    let length: Int64

    enum CodingKeys: String, CodingKey {
        case version = "VersionId"
        case hashType = "HashType"
        case _url = "Url"
        case hashBlockSize = "HashBlockSize"
        case hashes = "Hashes"
        case length = "Length"
    }

    static let dir = Util.applicationSupport.appendingPathComponent("patch")

    var url: URL {
        URL(string: _url)!
    }

    var name: String {
        [repo.rawValue, String(url.lastPathComponent.dropLast(6))].joined(
            separator: "/")
    }

    var path: String {
        url.pathComponents.dropFirst().joined(separator: "/")
    }

    var repo: FFXIVRepo {
        FFXIVRepo(rawValue: url.pathComponents[2])
            ?? (url.pathComponents[1] == "boot" ? .boot : .game)
    }

    static func totalLength(_ patches: [Patch]) -> Int64 {
        patches.map { $0.length }.reduce(0, +)
    }

    static func totalLength(_ patches: ArraySlice<Patch>) -> Int64 {
        totalLength(Array(patches))
    }

    private static let keepKey = "KeepPatches"
    static var keep: Bool {
        get {
            UserDefaults.standard.bool(forKey: keepKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keepKey)
        }
    }

    static var userAgent: String {
        String(cString: getPatcherUserAgent())
    }

    static var bootPatches: [Patch] {
        get throws {
            let patchesJSON = String(cString: getBootPatches())
            do {
                return try JSONDecoder().decode(
                    [Patch].self, from: patchesJSON.data(using: .utf8)!)
            } catch {
                throw XLError.runtimeError(patchesJSON).tryMap
            }
        }
    }

    func install() {
        let patchPath = Patch.dir.appendingPathComponent(path).path
        let patchPathCString = FileManager.default.fileSystemRepresentation(
            withPath: patchPath)
        let valid = checkPatchValidity(
            patchPathCString, Int(length), hashBlockSize, hashType,
            hashes?.joined(separator: ",") ?? "")
        guard valid else {
            DispatchQueue.main.sync {
                let alert = NSAlert()
                alert.addButton(
                    withTitle: NSLocalizedString(
                        "PATCH_ERROR_BUTTON", comment: ""))
                alert.alertStyle = .critical
                alert.messageText = NSLocalizedString(
                    "PATCH_ERROR_MESSAGE", comment: "")
                alert.informativeText = NSLocalizedString(
                    "PATCH_ERROR_INFORMATIVE", comment: "")
                alert.runModal()
                try! FileManager.default.removeItem(atPath: patchPath)
                Util.quit()
            }
            return
        }
        var repo = self.repo
        let res = String(
            cString: installPatch(patchPathCString, repo.patchURL.path))
        if res == "OK" {
            repo.ver = version
            Log.information("Updated ver to \(repo.ver)")
        } else {
            DispatchQueue.main.sync {
                let alert = NSAlert()
                alert.addButton(
                    withTitle: NSLocalizedString(
                        "PATCH_ERROR_MESSAGE", comment: ""))
                alert.alertStyle = .critical
                alert.messageText = NSLocalizedString(
                    "PATCH_ERROR_MESSAGE", comment: "")
                alert.informativeText = res
                alert.runModal()
                Util.quit()
            }
        }
        if !Patch.keep {
            try? FileManager.default.removeItem(atPath: patchPath)
        }
    }
}
