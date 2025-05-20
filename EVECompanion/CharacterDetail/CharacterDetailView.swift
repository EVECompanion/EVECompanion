//
//  CharacterDetailView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 10.05.24.
//

import SwiftUI
import EVECompanionKit
import Kingfisher

struct CharacterDetailView: View {
    
    @StateObject var character: ECKCharacter
    @StateObject var assetManager: ECKAssetManager
    @StateObject var contractManager: ECKContractManager
    @StateObject var industryJobsManager: ECKIndustryJobManager
    @StateObject var jumpClonesManager: ECKJumpClonesManager
    @StateObject var planetaryColoniesManager: ECKPlanetaryColonyManager
    @Binding var selectedCharacter: CharacterSelection
    
    init(character: ECKCharacter, selectedCharacter: Binding<CharacterSelection>) {
        self._character = StateObject(wrappedValue: character)
        self._assetManager = StateObject(wrappedValue: .init(character: character))
        self._contractManager = StateObject(wrappedValue: .init(character: character))
        self._industryJobsManager = StateObject(wrappedValue: .init(character: character))
        self._jumpClonesManager = StateObject(wrappedValue: .init(character: character))
        self._planetaryColoniesManager = StateObject(wrappedValue: .init(character: character))
        self._selectedCharacter = selectedCharacter
    }
    
    var body: some View {
        List {
            Section {
                NavigationLink(value: AppScreen.characterSheet(character)) {
                    HStack {
                        ECImage(id: character.id,
                                category: .character)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text("Character Sheet")
                            Text(character.name)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("Skills and Clones") {
                row(for: .skillQueue)
                row(for: .skills)
                row(for: .jumpClones)
            }
            
            Section("EVE Mail") {
                row(for: .mail)
            }
            
            Section("Inventory") {
                row(for: .assets)
            }
            
            Section("Industry") {
                row(for: .industryJobs)
                row(for: .planetaryColonies)
            }
            
            Section("Finance") {
                if let wallet = character.wallet {
                    row(for: .walletJournal(isk: wallet))
                } else {
                    row(for: .walletJournal(isk: nil))
                }
                row(for: .walletTransactions)
                row(for: .loyaltyPoints)
                row(for: .marketOrders)
                row(for: .contracts)
            }
        }
        .navigationTitle(character.name)
        .toolbar(content: {
            ToolbarItem {
                CharacterLogoutButton(character: character)
            }
        })
        .onAppear {
            selectedCharacter = .character(character)
        }
    }
    
    @ViewBuilder
    func row(for row: CharacterDetailRowType) -> some View {
        NavigationLink(value: destination(for: row, character: character)) {
            HStack(content: {
                Image(row.image)
                    .resizable()
                    .frame(width: 50, height: 50)
                VStack(alignment: .leading) {
                    Text(row.title)
                    
                    if let secondaryText = row.secondaryText {
                        Text(secondaryText)
                            .foregroundStyle(Color.secondary)
                    }
                }
                
            })
        }
    }
    
    func destination(for row: CharacterDetailRowType,
                     character: ECKCharacter) -> AppScreen {
        switch row {
        case .assets:
            return .assetList(manager: assetManager)
        case .contracts:
            return .contracts(manager: contractManager)
        case .marketOrders:
            return .marketOrders(character)
        case .walletJournal:
            return .walletJournal(character)
        case .walletTransactions:
            return .walletTransactions(character)
        case .loyaltyPoints:
            return .loyaltyPoints(character)
        case .mail:
            return .mail(character)
        case .skills:
            return .skills(character)
        case .skillQueue:
            return .skillQueue(character)
        case .industryJobs:
            return .industryJobs(manager: industryJobsManager)
        case .jumpClones:
            return .jumpClones(manager: jumpClonesManager)
        case .planetaryColonies:
            return .planetaryColonies(planetaryColoniesManager)
        }
    }
    
}

#Preview {
    NavigationStack {
        CharacterDetailView(character: .dummy, selectedCharacter: .constant(.empty))
    }
}
