//
//  ECKCorporationFeature.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.05.26.
//

import Foundation

public enum ECKCorporationFeature: Sendable {
    
    case walletTransactions
    case walletJournal
    case contracts
    case marketOrders
    case industryJobs
    
    public var requiredCorpRoles: [ECKCorporationRole] {
        switch self {
        case .walletTransactions:
            return ECKCorporationWalletTransactionsResource.requiredCorpRoles
        case .walletJournal:
            return ECKCorporationWalletJournalResource.requiredCorpRoles
        case .contracts:
            return ECKCorporationContractResource.requiredCorpRoles
        case .marketOrders:
            return ECKCorporationMarketOrdersResource.requiredCorpRoles
        case .industryJobs:
            return ECKCorporationIndustryJobsResource.requiredCorpRoles
        }
    }
    
}
