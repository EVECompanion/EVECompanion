//
//  ECKAppVariant.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 14.04.25.
//

import Foundation

enum ECKAppVariant: String {
    
    case dev = "de.schlabertz.EVECompanion.dev"
    case devWidgets = "de.schlabertz.EVECompanion.dev.Widgets"
    case beta = "de.schlabertz.EVECompanion.beta"
    case betaWidgets = "de.schlabertz.EVECompanion.beta.Widgets"
    case prod = "de.schlabertz.EVECompanion"
    case prodWidgets = "de.schlabertz.EVECompanion.Widgets"
    
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
    
    var appGroupIdentifier: String {
        switch self {
        case .dev,
             .devWidgets:
            return "group.de.schlabertz.EVECompanion.dev"
        case .beta,
             .betaWidgets:
            return "group.de.schlabertz.EVECompanion.beta"
        case .prod,
             .prodWidgets,
             .unknown:
            return "group.de.schlabertz.EVECompanion"
        }
    }
    
}
