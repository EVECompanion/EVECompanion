//
//  AppScreen.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 11.04.25.
//

import Foundation
import EVECompanionKit
import SwiftUI

enum AppScreen: Hashable {
    
    case characterList(Binding<CharacterSelection>)
    case characterDetail(ECKCharacter, Binding<CharacterSelection>)
    case characterSheet(ECKCharacter)
    
    case assetList(manager: ECKAssetManager)
    case contracts(manager: ECKContractManager)
    case marketOrders(ECKCharacter)
    case walletJournal(ECKCharacter)
    case walletTransactions(ECKCharacter)
    case loyaltyPoints(ECKCharacter)
    case mail(ECKCharacter)
    case skills(ECKCharacter)
    case skillQueue(ECKCharacter)
    case industryJobs(manager: ECKIndustryJobManager)
    case jumpClones(manager: ECKJumpClonesManager)
    case planetaryColonies(ECKPlanetaryColonyManager)
    case planetaryColony(ECKPlanetaryColonyManager.ECKColony)
    case fittingsList(ECKFittingManager)
    case fittingDetail(ECKCharacter, ECKCharacterFitting)
    
    case itemByTypeId(Int)
    case item(ECKItem)
    
    case universe
    case itemDatabase(groupIdFilter: Int?)
    case incursions
    case sovereigntyCampaigns
    
    case settings
    
    private var rawValue: String {
        switch self {
            
        case .characterList:
            return "characterList"
        case .characterDetail:
            return "characterDetail"
        case .characterSheet:
            return "characterSheet"
        case .assetList:
            return "assetList"
        case .contracts:
            return "contracts"
        case .marketOrders:
            return "marketOrders"
        case .walletJournal:
            return "walletJournal"
        case .walletTransactions:
            return "walletTransactions"
        case .loyaltyPoints:
            return "loyaltyPoints"
        case .mail:
            return "mail"
        case .skills:
            return "skills"
        case .skillQueue:
            return "skillQueue"
        case .industryJobs:
            return "industryJobs"
        case .jumpClones:
            return "jumpClones"
        case .item:
            return "item"
        case .itemByTypeId:
            return "itemByTypeId"
        case .universe:
            return "universe"
        case .itemDatabase:
            return "itemDatabase"
        case .incursions:
            return "incursions"
        case .sovereigntyCampaigns:
            return "sovereigntyCampaigns"
        case .settings:
            return "settings"
        case .planetaryColonies:
            return "planetaryColonies"
        case .planetaryColony:
            return "planetaryColony"
        case .fittingsList:
            return "fittingsList"
        case .fittingDetail:
            return "fittingDetail"
        }
    }
    
    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.characterList, .characterList),
             (.universe, .universe),
             (.incursions, .incursions),
             (.sovereigntyCampaigns, .sovereigntyCampaigns),
             (.settings, .settings):
            return true
        case (.characterDetail(let lhsCharacter, _), .characterDetail(let rhsCharacter, _)),
             (.characterSheet(let lhsCharacter), .characterSheet(let rhsCharacter)),
             (.marketOrders(let lhsCharacter), .marketOrders(let rhsCharacter)),
             (.walletJournal(let lhsCharacter), .walletJournal(let rhsCharacter)),
             (.walletTransactions(let lhsCharacter), .walletTransactions(let rhsCharacter)),
             (.loyaltyPoints(let lhsCharacter), .loyaltyPoints(let rhsCharacter)),
             (.mail(let lhsCharacter), .mail(let rhsCharacter)),
             (.skills(let lhsCharacter), .skills(let rhsCharacter)),
             (.skillQueue(let lhsCharacter), .skillQueue(let rhsCharacter)):
            return lhsCharacter == rhsCharacter
            
        case (.assetList(manager: let lhsManager), .assetList(manager: let rhsManager)):
            return lhsManager.character == rhsManager.character
            
        case (.contracts(manager: let lhsManager), .contracts(manager: let rhsManager)):
            return lhsManager.character == rhsManager.character
            
        case (.industryJobs(manager: let lhsManager), .industryJobs(manager: let rhsManager)):
            return lhsManager.character == rhsManager.character
            
        case (.jumpClones(manager: let lhsManager), .jumpClones(manager: let rhsManager)):
            return lhsManager.character == rhsManager.character
            
        case (.item(let lhsItem), .item(let rhsItem)):
            return lhsItem == rhsItem
            
        case (.planetaryColonies(let lhsManager), .planetaryColonies(let rhsManager)):
            return lhsManager.character == rhsManager.character
            
        case (.itemByTypeId(let lhsItemId), .itemByTypeId(let rhsItemId)):
            return lhsItemId == rhsItemId
            
        case (.planetaryColony(let lhsColony), .planetaryColony(let rhsColony)):
            return lhsColony.colony.planet.planetId == rhsColony.colony.planet.planetId
            
        case (.fittingsList(let lhsManager), .fittingsList(let rhsManager)):
            return lhsManager.character == rhsManager.character
            
        case (.fittingDetail(let lhsCharacter, let lhsFitting), .fittingDetail(let rhsCharacter, let rhsFitting)):
            return lhsCharacter == rhsCharacter && lhsFitting.id == rhsFitting.id
            
        case (.itemDatabase(let lhsFilter), .itemDatabase(let rhsFilter)):
            return lhsFilter == rhsFilter
            
        default:
            return false
            
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
        
        switch self {
        case .characterList:
            return
        case .characterDetail(let character, _):
            hasher.combine(character)
        case .characterSheet(let character):
            hasher.combine(character)
        case .assetList(let manager):
            hasher.combine(manager.character)
        case .contracts(let manager):
            hasher.combine(manager.character)
        case .marketOrders(let character):
            hasher.combine(character)
        case .walletJournal(let character):
            hasher.combine(character)
        case .walletTransactions(let character):
            hasher.combine(character)
        case .loyaltyPoints(let character):
            hasher.combine(character)
        case .mail(let character):
            hasher.combine(character)
        case .skills(let character):
            hasher.combine(character)
        case .skillQueue(let character):
            hasher.combine(character)
        case .industryJobs(let manager):
            hasher.combine(manager.character)
        case .jumpClones(let manager):
            hasher.combine(manager.character)
        case .item(let item):
            hasher.combine(item)
        case .itemByTypeId(let typeId):
            hasher.combine(typeId)
        case .planetaryColonies(let manager):
            hasher.combine(manager.character)
        case .planetaryColony(let colony):
            hasher.combine(colony.colony)
        case .fittingsList(let manager):
            hasher.combine(manager.character)
        case .fittingDetail(let character, let fitting):
            hasher.combine(character)
            hasher.combine(fitting)
        case .universe:
            return
        case .itemDatabase(let filter):
            hasher.combine(filter)
        case .incursions:
            return
        case .sovereigntyCampaigns:
            return
        case .settings:
            return
        }
    }
    
}
