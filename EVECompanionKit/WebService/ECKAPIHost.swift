//
//  ECKAPIHost.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation

enum Host {
    
    case eveLogin
    case esi
    case image
    
    case evecompanionAPI
    
    private static func evecompanionAPIHost(for appVariant: ECKAppVariant) -> String {
        switch ECKAppVariant.current {
        case .dev,
             .devWidgets,
             .beta,
             .betaWidgets:
            return "staging-api.evecompanion.app"
        case .prod,
             .prodWidgets,
             .unknown:
            return "api.evecompanion.app"
        }
    }
    
    var value: String {
        switch self {
        case .eveLogin:
            return "login.eveonline.com"
        case .esi:
            return "esi.evetech.net"
        case .image:
            return "images.evetech.net"
        case .evecompanionAPI:
            return Self.evecompanionAPIHost(for: .current)
        }
    }
    
}
