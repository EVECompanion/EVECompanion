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
    
    public enum Source: Equatable, Hashable, Sendable {
        case character(ECKCharacter)
        case corporation(ECKAuthenticatedCorporation)
        
        fileprivate func resource(division: ECKCorporationWalletDivision?) -> ECKWebResource<[ECKWalletJournalEntry]>? {
            switch self {
            case .character(let character):
                return ECKCharacterWalletJournalResource(token: character.token)
            case .corporation(let corporation):
                guard let corpId = corporation.corpId else {
                    return nil
                }
                
                guard let roles = corporation.roles else {
                    return nil
                }
                
                guard let division else {
                    return nil
                }
                
                return ECKCorporationWalletJournalResource(
                    corporationId: corpId,
                    division: division.division,
                    token: corporation.authenticatingCharacter.token,
                    currentRoles: roles
                )
            }
        }
        
        public var id: Int {
            switch self {
            case .character(let character):
                return character.id
            case .corporation(let corporation):
                return corporation.corpId ?? -1
            }
        }
    }
    
    public let source: Source
    let isPreview: Bool
    
    @Published public var loadingState: ECKLoadingState = .loading
    
    // Entries for the currently selected source/division
    public var entries: [ECKWalletJournalEntry] {
        return _entries[selectedDivisionId ?? 0] ?? []
    }
    @Published private var _entries: [Int: [ECKWalletJournalEntry]] = [:]
    
    // Corporation wallet division support (unused for character source)
    @Published public var walletDivisions: [ECKCorporationWalletDivision] = []
    @Published public var selectedDivisionId: Int?
    
    public var selectedDivision: ECKCorporationWalletDivision? {
        guard walletDivisions.isEmpty == false else {
            return nil
        }
        
        return walletDivisions.first(where: { $0.division == selectedDivisionId }) ?? walletDivisions.first
    }
    
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
    
    // MARK: - Initializers
    
    public convenience init(character: ECKCharacter, isPreview: Bool = false) {
        self.init(source: .character(character), isPreview: isPreview)
    }
    
    public convenience init(corporation: ECKAuthenticatedCorporation, isPreview: Bool = false) {
        self.init(source: .corporation(corporation), isPreview: isPreview)
    }
    
    public init(source: Source, isPreview: Bool = false) {
        self.source = source
        self.isPreview = isPreview
        Task { @MainActor in
            await loadWalletJournal()
        }
    }
    
    // MARK: - Loading
    
    @MainActor
    public func loadWalletDivisions() async {
        guard case .corporation(let corporation) = source else {
            return
        }
        
        if corporation.walletDivisions == nil || corporation.walletDivisionsLoadingState.isLoading {
            if let loadingTask = corporation.walletDivisionsLoadingTask {
                await loadingTask.value
            } else {
                await corporation.loadWalletDivisions()
            }
        }
        
        walletDivisions = corporation.walletDivisions ?? []
        selectDefaultDivisionIfNeeded()
    }
    
    @MainActor
    public func loadWalletJournal(forceReload: Bool = false) async {
        guard UserDefaults.standard.isDemoModeEnabled == false && isPreview == false else {
            walletDivisions = demoWalletDivisions
            selectDefaultDivisionIfNeeded()
            _entries[selectedDivision?.division ?? 0] = [.dummy1, .dummy2, .dummy3]
            loadingState = .ready
            return
        }
        
        guard _entries[selectedDivisionId ?? 0] == nil || forceReload else {
            return
        }
        
        if case .corporation = source {
            await loadWalletDivisions()
        }
        
        if entries.isEmpty {
            loadingState = .loading
        } else {
            loadingState = .reloading
        }
        
        guard let resource = source.resource(division: selectedDivision) else {
            loadingState = .ready
            return
        }
        
        do {
            let response = try await ECKWebService()
                .loadResource(resource: resource)
                .response
            
            _entries[selectedDivision?.division ?? 0] = response
            loadingState = .ready
        } catch {
            logger.error("Error loading wallet journal data: \(String(describing: error))")
            loadingState = .error(error)
        }
    }
    
    // MARK: - Division selection
    
    @MainActor
    public func selectDivision(id: Int?) {
        guard selectedDivisionId != id else {
            return
        }
        
        selectedDivisionId = id
    }
    
    @MainActor
    public func selectDefaultDivisionIfNeeded() {
        guard selectedDivisionId == nil else {
            return
        }
        
        selectedDivisionId = walletDivisions.first?.division
    }
    
    private var demoWalletDivisions: [ECKCorporationWalletDivision] {
        switch source {
        case .character:
            return []
        case .corporation(let corporation):
            return corporation.walletDivisions ?? [
                .init(division: 1, balance: 4_250_000_000, name: "Master Wallet"),
                .init(division: 2, balance: 980_000_000, name: "Operations")
            ]
        }
    }
}

private extension ECKLoadingState {
    var isLoading: Bool {
        switch self {
        case .loading, .reloading:
            return true
        case .ready, .error:
            return false
        }
    }
}
