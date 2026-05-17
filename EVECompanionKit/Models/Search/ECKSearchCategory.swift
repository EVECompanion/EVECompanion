//
//  ECKSearchCategory.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 17.05.26.
//

import Foundation

enum ECKSearchCategory: String, CaseIterable, Sendable {
    case agent
    case alliance
    case character
    case constellation
    case corporation
    case faction
    case inventoryType = "inventory_type"
    case region
    case solarSystem = "solar_system"
    case station
    case structure
}
