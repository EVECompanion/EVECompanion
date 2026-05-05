//
//  ECKWalletJournalManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 05.05.26.
//

import Foundation
public import Combine

public enum ECKWalletJournalAmountFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case income
    case expense
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .all: return "All"
        case .income: return "Income"
        case .expense: return "Expense"
        }
    }
}

public class ECKWalletJournalManager: ObservableObject, @unchecked Sendable {
    
    public let character: ECKCharacter
    public let isPreview: Bool
    
    @Published public var loadingState: ECKLoadingState = .loading
    @Published public var entries: [ECKWalletJournalEntry] = []
    
    @Published public var amountFilter: ECKWalletJournalAmountFilter = .all
    
    public var filteredEntries: [ECKWalletJournalEntry] {
        entries.filter { entry in
            switch amountFilter {
            case .all:
                return true
            case .income:
                guard let amount = entry.amount else {
                    return false
                }
                return amount > 0
            case .expense:
                guard let amount = entry.amount else {
                    return false
                }
                return amount < 0
            }
        }
    }
    
    public init(character: ECKCharacter, isPreview: Bool = false) {
        self.character = character
        self.isPreview = isPreview
        Task { @MainActor in
            await load()
        }
    }
    
    @MainActor
    public func load() async {
        guard UserDefaults.standard.isDemoModeEnabled == false && isPreview == false else {
            self.entries = [.dummy1, .dummy2, .dummy3]
            self.loadingState = .ready
            return
        }
        
        loadingState = .loading
        let resource = ECKCharacterWalletJournalResource(token: character.token)
        do {
            self.entries = try await ECKWebService().loadResource(resource: resource).response
            loadingState = .ready
        } catch {
            logger.error("Error loading wallet journal data: \(String(describing: error))")
            loadingState = .error(error)
        }
    }
    
    @MainActor
    public func reload() async {
        await load()
    }
}
