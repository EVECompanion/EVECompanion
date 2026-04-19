//
//  CorporationDetailRowType.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 24.03.26.
//

import Foundation

enum CorporationDetailRowType {
    
    case contracts
    case marketOrders
    case industryJobs
    
    var title: String {
        switch self {
        case .contracts:
            return "Contracts"
        case .marketOrders:
            return "Market Orders"
        case .industryJobs:
            return "Industry Jobs"
        }
    }
    
    var secondaryText: String? {
        switch self {
        case .contracts:
            return nil
        case .marketOrders:
            return nil
        case .industryJobs:
            return nil
        }
    }
    
    var image: String {
        switch self {
        case .contracts:
            return "Neocom/Contracts"
        case .marketOrders:
            return "Neocom/MarketOrders"
        case .industryJobs:
            return "Neocom/Industry"
        }
    }
    
}
