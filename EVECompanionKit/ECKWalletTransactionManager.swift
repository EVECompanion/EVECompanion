//
//  ECKWalletTransactionManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 29.04.26.
//

import Foundation
public import Combine

public class ECKWalletTransactionManager: ObservableObject, @unchecked Sendable {
    
    public enum Source: Equatable, Hashable, Sendable {
        case character(ECKCharacter)
        case corporation(ECKAuthenticatedCorporation)
        
        fileprivate func resource(division: ECKCorporationWalletDivision?) -> ECKWebResource<[ECKWalletTransactionEntry]>? {
            switch self {
            case .character(let character):
                return ECKCharacterWalletTransactionResource(token: character.token)
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
                
                return ECKCorporationWalletTransactionsResource(
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
    
    nonisolated public let source: Source
    let isPreview: Bool
    
    @Published public var loadingState: ECKLoadingState = .loading
    public var walletTransactions: [ECKWalletTransactionEntry] {
        return _walletTransactions[selectedDivisionId ?? 0] ?? []
    }
    @Published private var _walletTransactions: [Int: [ECKWalletTransactionEntry]] = [:]
    @Published public var walletDivisions: [ECKCorporationWalletDivision] = []
    @Published public var selectedDivisionId: Int?
    
    public var selectedDivision: ECKCorporationWalletDivision? {
        guard walletDivisions.isEmpty == false else {
            return nil
        }
        
        return walletDivisions.first(where: { $0.division == selectedDivisionId }) ?? walletDivisions.first
    }
    
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
            await loadWalletTransactions()
        }
    }
    
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
    public func loadWalletTransactions(forceReload: Bool = false) async {
        guard UserDefaults.standard.isDemoModeEnabled == false && isPreview == false else {
            walletDivisions = demoWalletDivisions
            selectDefaultDivisionIfNeeded()
            loadingState = .ready
            return
        }
        
        guard _walletTransactions[selectedDivisionId ?? 0] == nil || forceReload else {
            return
        }
        
        if case .corporation = source {
            await loadWalletDivisions()
        }
        
        if walletTransactions.isEmpty {
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
            
            _walletTransactions[selectedDivision?.division ?? 0] = response
            loadingState = .ready
        } catch {
            logger.error("Error loading wallet transaction data: \(String(describing: error))")
            loadingState = .error(error)
        }
    }
    
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
                .init(division: 1, balance: 4250000000, name: "Master Wallet"),
                .init(division: 2, balance: 980000000, name: "Operations")
            ]
        }
    }
    
}

private extension ECKLoadingState {
    
    var isLoading: Bool {
        switch self {
        case .loading,
             .reloading:
            return true
        case .ready,
             .error:
            return false
        }
    }
    
}
