//
//  PrefixMigrator.swift
//  XIV on Mac
//
//  Created by Chris Backas on 5/25/22.
//

import Foundation

class PrefixMigrator {
    static func migratePrefixIfNeeded() -> Bool {
        // Do we need to do anything? If there's a "game" folder in our prefix, then we need to migrate.
        let oldGameDirectory: URL = Util.applicationSupport.appendingPathComponent("game/", isDirectory: true)
        if !Util.pathExists(path: oldGameDirectory) {
            Log.debug("Prefix Migration: No migration required.")
            return false
        }
        
        Log.information("Prefix Migration: Existing prefix needs migration.")
        let oldPrefixPath: URL = Util.applicationSupport.appendingPathComponent("wineprefix_old/", isDirectory: true)
        let newPrefixPath: URL = Wine.prefix
        if !Util.pathExists(path: newPrefixPath) {
            do {
                try FileManager.default.createDirectory(atPath: newPrefixPath.path, withIntermediateDirectories: true, attributes: nil)
            }
            catch let createError as NSError {
                Log.error("Prefix Migration: Failed to create new prefix \(newPrefixPath): \(createError.localizedDescription)")
                // If this failed, the rest will not go well...
                return true // This doesn't mean success, just that migration was needed/attempted
            }
        }
        
        if Settings.gamePath.path.hasPrefix(Util.applicationSupport.appendingPathComponent("game/", isDirectory: true).path) {
            Log.information("Prefix Migration: Setting GamePath to new default.")
            // Preference was set to the default location explicitly previously
            Settings.setDefaultGamepath()
        }
        
        // Clean up items (EG: old logs) from old location
        let deleteItems: [URL] = [Util.applicationSupport.appendingPathComponent("app.log", isDirectory: false),
                                  Util.applicationSupport.appendingPathComponent("wine.log", isDirectory: false)]
        for oneDeleteItem in deleteItems {
            if Util.pathExists(path: oneDeleteItem) {
                do {
                    try FileManager.default.removeItem(at: oneDeleteItem)
                }
                catch let createError as NSError {
                    Log.error("Prefix Migration: Failed to create new prefix \(newPrefixPath): \(createError.localizedDescription)")
                }
            }
        }

        // Step 1: Move entire old prefix to backup location.
        Log.information("Prefix Migration: Archiving existing prefix: \"\(oldGameDirectory.path)\" -> \"\(oldPrefixPath.path)\"")
        
        do {
            try FileManager.default.moveItem(at: oldGameDirectory, to: oldPrefixPath)
        }
        catch {
            Log.error("Prefix Migration: Failed to move wine prefix: \(error.localizedDescription)")
            return false
        }
        
        // Now retrieve some stuff from the old prefix into the new.
        let oldProgramFilesXIVOnMacPath = oldPrefixPath.appendingPathComponent("drive_c/Program Files/XIV on Mac/", isDirectory: true)
        let itemsToRetrieve: [(URL, URL)] = [
            // First we move the game data itself
            (oldPrefixPath.appendingPathComponent("drive_c/Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn/", isDirectory: true),
             Util.applicationSupport.appendingPathComponent("ffxiv/", isDirectory: true)),
            
            // Dalamud stuff
            (oldProgramFilesXIVOnMacPath.appendingPathComponent("devPlugins/", isDirectory: true),
             Util.applicationSupport.appendingPathComponent("devPlugins/", isDirectory: true)),
            (oldProgramFilesXIVOnMacPath.appendingPathComponent("installedPlugins/", isDirectory: true),
             Util.applicationSupport.appendingPathComponent("installedPlugins/", isDirectory: true)),
            (oldProgramFilesXIVOnMacPath.appendingPathComponent("pluginConfigs/", isDirectory: true),
             Util.applicationSupport.appendingPathComponent("pluginConfigs/", isDirectory: true)),
            (oldProgramFilesXIVOnMacPath.appendingPathComponent("dalamudconfig.json", isDirectory: false),
             Util.applicationSupport.appendingPathComponent("dalamudconfig.json", isDirectory: false)),

            // ACT stuff
            (oldPrefixPath.appendingPathComponent("drive_c/users/emet-selch/Application Data/Advanced Combat Tracker/", isDirectory: true),
             newPrefixPath.appendingPathComponent("drive_c/users/emet-selch/Application Data/Advanced Combat Tracker/", isDirectory: true))
        ]
        
        for oneItem in itemsToRetrieve {
            let oldPath: URL = oneItem.0
            let newPath: URL = oneItem.1
            if Util.pathExists(path: oldPath) {
                // Check if the parent path or our target exists
                let newPathParent: URL = newPath.deletingLastPathComponent()
                if !Util.pathExists(path: newPathParent) {
                    Log.information("Prefix Migration: Need to create \"\(newPathParent.path)\"")
                    do {
                        try FileManager.default.createDirectory(at: newPathParent, withIntermediateDirectories: true)
                    }
                    catch let createError as NSError {
                        Log.error("Prefix Migration: Failed to create \(newPathParent.path): \(createError.localizedDescription)")
                        // Move on to the next item, the copy will fail if we try.
                        continue
                    }
                }
                // Get rid of an existing version at the destination
                if Util.pathExists(path: newPath) {
                    // If removal fails we'll try to move anyway I guess...
                    do {
                        try FileManager.default.removeItem(at: newPath)
                    }
                    catch let removeError as NSError {
                        Log.error("Prefix Migration: Failed to remove \(oldPath): \(removeError.localizedDescription)")
                    }
                }
                // If this fails we should try the other stuff. Better to make a best effort than the block the user entirely.
                Log.information("Prefix Migration: Retrieving \"\(oldPath.path)\" -> \"\(newPath.path)\"")
                do {
                    try FileManager.default.moveItem(at: oldPath, to: newPath)
                }
                catch let moveError as NSError {
                    Log.error("Prefix Migration: Failed to retrieve \(oldPath.lastPathComponent): \(moveError.localizedDescription)")
                }
            }
        }
        
        Log.information("Prefix Migration: Migration Complete.")
        return true
    }
    
    static func migrateWineRegistrySettings() {
        // And finally, let's assert that preferences backed by registry keys need to have their keys re-set to match our preference files.
        // Since the setters don't check that the value isn't changing, we can just set them to their current values to get the registry updated.
        DispatchQueue.global(qos: .utility).async {
            Wine.retina = Wine.retina
            Settings.platform = Settings.platform
        }
    }
}
