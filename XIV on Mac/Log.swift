//
//  Log.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 23.05.22.
//

import Foundation
import Serilog

struct Log {
    @available(*, unavailable) private init() {}
    
    private enum EventLevel: UInt8 {
        /// <summary>
        /// Anything and everything you might want to know about
        /// a running block of code.
        /// </summary>
        case verbose
        
        /// <summary>
        /// Internal system events that aren't necessarily
        /// observable from the outside.
        /// </summary>
        case debug
        
        /// <summary>
        /// The lifeblood of operational intelligence - things
        /// happen.
        /// </summary>
        case information
        
        /// <summary>
        /// Service is degraded or endangered.
        /// </summary>
        case warning
        
        /// <summary>
        /// Functionality is unavailable, invariants are broken
        /// or data is lost.
        /// </summary>
        case error
        
        /// <summary>
        /// If you have a pager, it goes off when one of these
        /// occurs.
        /// </summary>
        case fatal
    }
    
    static func verbose(_ message: CustomStringConvertible) {
        writeLogLine(EventLevel.verbose.rawValue, message.description)
    }
    
    static func debug(_ message: CustomStringConvertible) {
        writeLogLine(EventLevel.debug.rawValue, message.description)
    }
    
    static func information(_ message: CustomStringConvertible) {
        writeLogLine(EventLevel.information.rawValue, message.description)
    }
    
    static func warning(_ message: CustomStringConvertible) {
        writeLogLine(EventLevel.warning.rawValue, message.description)
    }
    
    static func error(_ message: CustomStringConvertible) {
        writeLogLine(EventLevel.error.rawValue, message.description)
    }
    
    static func fatal(_ message: CustomStringConvertible) {
        writeLogLine(EventLevel.fatal.rawValue, message.description)
    }
}
