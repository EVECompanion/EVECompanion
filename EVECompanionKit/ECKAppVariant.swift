//
//  ECKAppVariant.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 14.04.25.
//

import Foundation

enum ECKAppVariant: String {
    
    case dev = "de.schlabertz.EVECompanion.dev"
    case beta = "de.schlabertz.EVECompanion.beta"
    case prod = "de.schlabertz.EVECompanion"
    
    case unknown
    
    static var current: ECKAppVariant {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            logger.error("No bundleIdentifier found for Bundle.main")
            return .unknown
        }
        
        guard let variant = ECKAppVariant(rawValue: bundleIdentifier) else {
            logger.error("Unknown bundleIdentifier \(bundleIdentifier) found for Bundle.main")
            return .unknown
        }
        
        logger.info("Detected app variant \(variant)")
        
        return variant
    }
    
}
