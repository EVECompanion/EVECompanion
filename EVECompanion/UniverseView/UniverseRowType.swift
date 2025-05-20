//
//  UniverseRowType.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import SwiftUI

enum UniverseRowType {
    
    case incursions
    case sovereigntyCampaigns
    case itemDatabase
    
    var title: String {
        switch self {
        case .incursions:
            return "Incursions"
        case .sovereigntyCampaigns:
            return "Sovereignty Campaigns"
        case .itemDatabase:
            return "Item Database"
        }
    }
    
    var image: String {
        switch self {
        case .incursions:
            return "Universe/Incursions"
        case .sovereigntyCampaigns:
            return "Universe/Sovereignty"
        case .itemDatabase:
            return "Neocom/Inventory"
        }
    }
    
    var destination: AppScreen {
        switch self {
        case .incursions:
            return .incursions
        case .sovereigntyCampaigns:
            return .sovereigntyCampaigns
        case .itemDatabase:
            return .itemDatabase
        }
    }
    
}
