//
//  CorporationDetailRowType.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 24.03.26.
//

import Foundation
import EVECompanionKit

enum CorporationDetailRowType {
    
    case walletTransactions
    case walletJournal
    case contracts
    case marketOrders
    case industryJobs
    
    var feature: ECKCorporationFeature {
        switch self {
        case .walletTransactions:
            return .walletTransactions
        case .walletJournal:
            return .walletJournal
        case .contracts:
            return .contracts
        case .marketOrders:
            return .marketOrders
        case .industryJobs:
            return .industryJobs
        }
    }
    
    var title: String {
        switch self {
        case .walletJournal:
            return "Wallet Journal"
        case .walletTransactions:
            return "Wallet Transactions"
        case .contracts:
            return "Contracts"
        case .marketOrders:
            return "Market Orders"
        case .industryJobs:
            return "Industry Jobs"
        }
    }
    
    var secondaryText: String? {
        nil
    }
    
    var image: String {
        switch self {
        case .walletJournal:
            return "Neocom/Wallet"
        case .walletTransactions:
            return "Neocom/Journal"
        case .contracts:
            return "Neocom/Contracts"
        case .marketOrders:
            return "Neocom/MarketOrders"
        case .industryJobs:
            return "Neocom/Industry"
        }
    }
    
    func secondaryText(for corporation: ECKAuthenticatedCorporation) -> String? {
        corporation.roleRequirementDescription(for: feature) ?? secondaryText
    }
    
    func isEnabled(for corporation: ECKAuthenticatedCorporation) -> Bool {
        corporation.hasRequiredRoles(for: feature)
    }
    
}
