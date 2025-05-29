//
//  Coordinator.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 11.04.25.
//

import Foundation
import SwiftUI

@MainActor
class Coordinator: ObservableObject {
    
    @Published var path: NavigationPath
    let initialScreen: AppScreen
    
    init(initialScreen: AppScreen) {
        self.initialScreen = initialScreen
        self.path = NavigationPath()
    }
    
    func push(screen: AppScreen) {
        path.append(screen)
    }
    
    @ViewBuilder
    func createView(for screen: AppScreen) -> some View {
        switch screen {
        case .characterList(let selectedCharacterBinding):
            CharacterListView(selectedCharacter: selectedCharacterBinding)
        case .characterDetail(let character, let selectedCharacterBinding):
            CharacterDetailView(character: character, selectedCharacter: selectedCharacterBinding)
        case .characterSheet(let character):
            CharacterSheet(character: character)
        case .assetList(manager: let manager):
            AssetsListView(assetManager: manager)
        case .contracts(manager: let manager):
            ContractsListView(contractManager: manager)
        case .marketOrders(let character):
            MarketOrdersView(character: character)
        case .walletJournal(let character):
            WalletJournalView(character: character)
        case .walletTransactions(let character):
            WalletTransactionsView(character: character)
        case .loyaltyPoints(let character):
            LoyaltyPointsView(character: character)
        case .planetaryColonies(let manager):
            PlanetaryColoniesView(colonyManager: manager)
        case .planetaryColony(let colony):
            PlanetaryColonyView(colony: colony)
        case .mail(let character):
            MailboxView(character: character)
        case .skills(let character):
            SkillsView(character: character)
        case .skillQueue(let character):
            SkillQueueView(character: character)
        case .industryJobs(manager: let manager):
            IndustryJobsView(industryJobsManager: manager)
        case .jumpClones(manager: let manager):
            JumpClonesView(jumpClonesManager: manager)
        case .fittingsList(let manager):
            FittingsListView(fittingManager: manager)
        case .fittingDetail(let fitting):
            FittingDetailView(fitting: fitting)
        case .item(let item):
            ItemView(item: item)
        case .itemByTypeId(let typeId):
            ItemView(item: .init(typeId: typeId))
        case .universe:
            UniverseView()
        case .itemDatabase:
            MarketGroupsView()
        case .incursions:
            IncursionsView()
        case .sovereigntyCampaigns:
            SovereigntyCampaignsView()
        case .settings:
            SettingsView()
        }
    }
    
}
