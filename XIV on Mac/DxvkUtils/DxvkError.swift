//
//  DxvkError.swift
//  DxvkStateCacheMerger
//
//  Created by Marc-Aurel Zent on 30.03.22.
//

import Foundation

enum DxvkError: Error {
    case invalidHeader
    case invalidEntryHeader
    case invalidEntryData
}
