//
//  CharacterDetailRowType.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 11.05.24.
//

import SwiftUI
import EVECompanionKit

enum CharacterDetailRowType {
    
    case assets
    case contracts
    case marketOrders
    case walletJournal(isk: Double?)
    case walletTransactions
    case loyaltyPoints
    case mail
    case skills
    case skillQueue
    case industryJobs
    case jumpClones
    case planetaryColonies
    case fittings
    case skillPlans
    
    var title: String {
        switch self {
            
        case .assets:
            return "Assets"
        case .contracts:
            return "Contracts"
        case .marketOrders:
            return "Market Orders"
        case .walletJournal:
            return "Wallet Journal"
        case .walletTransactions:
            return "Transactions"
        case .loyaltyPoints:
            return "Loyalty Points"
        case .mail:
            return "Mail"
        case .skills:
            return "Skills"
        case .skillQueue:
            return "Skillqueue"
        case .industryJobs:
            return "Industry Jobs"
        case .jumpClones:
            return "Jump Clones"
        case .planetaryColonies:
            return "Planetary Colonies"
        case .fittings:
            return "Fittings"
        case .skillPlans:
            return "Skill Plans"
            
        }
    }
    
    var secondaryText: String? {
        switch self {
        case .assets:
            return nil
            
        case .contracts:
            return nil
            
        case .marketOrders:
            return nil
            
        case .walletJournal(let isk):
            if let isk {
                return "\(ECFormatters.iskLong(isk)) ISK"
            } else {
                return nil
            }
            
        case .walletTransactions:
            return nil
            
        case .loyaltyPoints:
            return nil
            
        case .mail:
            return nil
            
        case .skills:
            return nil
            
        case .skillQueue:
            return nil
            
        case .industryJobs:
            return nil
            
        case .jumpClones:
            return nil
            
        case .planetaryColonies:
            return nil
            
        case .fittings:
            return nil
            
        case .skillPlans:
            return nil
            
        }
    }
    
    var image: String {
        switch self {
            
        case .assets:
            return "Neocom/Assets"
        case .contracts:
            return "Neocom/Contracts"
        case .marketOrders:
            return "Neocom/MarketOrders"
        case .walletJournal:
            return "Neocom/Wallet"
        case .walletTransactions:
            return "Neocom/Journal"
        case .loyaltyPoints:
            return "Neocom/LPStore"
        case .mail:
            return "Neocom/Mail"
        case .skills:
            return "Neocom/Skills"
        case .skillQueue:
            return "Neocom/Skillqueue"
        case .industryJobs:
            return "Neocom/Industry"
        case .jumpClones:
            return "Neocom/JumpClones"
        case .planetaryColonies:
            return "Neocom/PlanetaryColonies"
        case .fittings:
            return "Neocom/Fitting"
        case .skillPlans:
            return "Neocom/Biography"
        }
    }
    
}
