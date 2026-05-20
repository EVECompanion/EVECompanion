//
//  ECKWalletTransactionManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 29.04.26.
//

import Foundation
public import Combine

public class ECKWalletTransactionManager: ObservableObject, ECKPageLoadable, @unchecked Sendable {
    
    private final class CursorPagination: @unchecked Sendable {
        var nextFromId: Int?
        var hasNextPage = true
        var isLoading = false
        
        func reset() {
            nextFromId = nil
            hasNextPage = true
            isLoading = false
        }
    }
    
    public enum Source: Equatable, Hashable, Sendable {
        case character(ECKCharacter)
        case corporation(ECKAuthenticatedCorporation)
        
        fileprivate func resource(fromId: Int?, division: ECKCorporationWalletDivision?) -> ECKWebResource<[ECKWalletTransactionEntry]>? {
            switch self {
            case .character(let character):
                return ECKCharacterWalletTransactionResource(token: character.token, fromId: fromId)
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
                    fromId: fromId,
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
    
    private var paginations: [Int: CursorPagination] = [:]
    
    public var selectedDivision: ECKCorporationWalletDivision? {
        guard walletDivisions.isEmpty == false else {
            return nil
        }
        
        return walletDivisions.first(where: { $0.division == selectedDivisionId }) ?? walletDivisions.first
    }
    
    public var elements: [ECKWalletTransactionEntry] {
        walletTransactions
    }
    
    public var hasNextPage: Bool {
        pagination.hasNextPage
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
    
    private var currentDivisionKey: Int {
        selectedDivision?.division ?? selectedDivisionId ?? 0
    }
    
    private var pagination: CursorPagination {
        let key = currentDivisionKey
        
        if let pagination = paginations[key] {
            return pagination
        }
        
        let pagination = CursorPagination()
        paginations[key] = pagination
        return pagination
    }
    
    @MainActor
    public func loadWalletTransactions(forceReload: Bool = false) async {
        guard pagination.isLoading == false else {
            return
        }
        
        guard UserDefaults.standard.isDemoModeEnabled == false && isPreview == false else {
            walletDivisions = demoWalletDivisions
            selectDefaultDivisionIfNeeded()
            _walletTransactions[currentDivisionKey] = [.dummy1, .dummy2]
            let pagination = CursorPagination()
            pagination.hasNextPage = false
            paginations[currentDivisionKey] = pagination
            loadingState = .ready
            return
        }
        
        if case .corporation = source {
            await loadWalletDivisions()
        }
        
        if forceReload == false,
           _walletTransactions[currentDivisionKey] != nil {
            return
        }
        
        if walletTransactions.isEmpty {
            loadingState = .loading
        } else {
            loadingState = .reloading
        }
        
        guard let resource = source.resource(fromId: nil, division: selectedDivision) else {
            let pagination = CursorPagination()
            pagination.hasNextPage = false
            paginations[currentDivisionKey] = pagination
            loadingState = .ready
            return
        }
        
        do {
            pagination.reset()
            try await loadPage(with: resource, isFirstPage: true)
            loadingState = .ready
        } catch {
            logger.error("Error loading wallet transaction data: \(String(describing: error))")
            loadingState = .error(error)
        }
    }
    
    @MainActor
    public func reload() async {
        pagination.reset()
        await loadWalletTransactions(forceReload: true)
    }
    
    @MainActor
    public func loadNextPage() async throws(ECKWebError) {
        guard pagination.isLoading == false else {
            return
        }
        
        guard hasNextPage else {
            return
        }
        
        guard let fromId = pagination.nextFromId else {
            pagination.hasNextPage = false
            return
        }
        
        guard let resource = source.resource(fromId: fromId, division: selectedDivision) else {
            return
        }
        
        try await loadPage(with: resource, isFirstPage: false)
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
    
    @MainActor
    private func loadPage(with resource: ECKWebResource<[ECKWalletTransactionEntry]>, isFirstPage: Bool) async throws(ECKWebError) {
        let key = currentDivisionKey
        
        pagination.isLoading = true
        defer {
            pagination.isLoading = false
        }
        
        let response = try await ECKWebService().loadResource(resource: resource)
        let loadedEntries = response.response.filter({ $0.transactionId != pagination.nextFromId })
        
        if isFirstPage {
            _walletTransactions[key] = loadedEntries
        } else {
            _walletTransactions[key, default: []].append(contentsOf: loadedEntries)
        }
        
        pagination.nextFromId = loadedEntries.last?.id
        pagination.hasNextPage = loadedEntries.isEmpty == false
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
        case .loading,
             .reloading:
            return true
        case .ready,
             .error:
            return false
        }
    }
    
}
