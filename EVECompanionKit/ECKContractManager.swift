//
//  ECKContractManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 11.05.24.
//

public import Combine

public class ECKContractManager: ObservableObject, @unchecked Sendable {
    
    public enum Source: Equatable, Hashable {
        case character(ECKCharacter)
        case corporation(ECKAuthenticatedCorporation)
        
        internal var resource: ECKWebResource<[ECKContract]>? {
            switch self {
            case .character(let character):
                return ECKCharacterContractResource(token: character.token)
            case .corporation(let corporation):
                guard let corpId = corporation.corpId else {
                    return nil
                }
                
                return ECKCorporationContractResource(corporationId: corpId, token: corporation.authenticatingCharacter.token)
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
    @Published public var contracts: [ECKContract] = []
    
    public var outstandingContracts: [ECKContract] {
        return contracts.filter { contract in
            return contract.status == .outstanding
        }
    }
    
    public var inProgressContracts: [ECKContract] {
        return contracts.filter { contract in
            return contract.status == .inProgress
        }
    }
    
    public var failedContracts: [ECKContract] {
        return contracts.filter { contract in
            return contract.status == .failed || contract.status == .rejected
        }
    }
    
    public var finishedContracts: [ECKContract] {
        return contracts.filter { contract in
            switch contract.status {
            case .outstanding,
                 .reversed,
                 .rejected,
                 .failed,
                 .inProgress:
                return false
            case .finishedIssuer,
                 .finishedContractor,
                 .finished,
                 .cancelled,
                 .deleted:
                return true
            }
        }
    }
    
    public convenience init(corporation: ECKAuthenticatedCorporation, isPreview: Bool = false) {
        self.init(source: .corporation(corporation), isPreview: isPreview)
    }
    
    public convenience init(character: ECKCharacter, isPreview: Bool = false) {
        self.init(source: .character(character), isPreview: isPreview)
    }
    
    public init(source: Source, isPreview: Bool = false) {
        self.source = source
        self.isPreview = isPreview
        Task { @MainActor in
            await loadContracts()
        }
    }
    
    @MainActor
    public func loadContracts() async {
        guard UserDefaults.standard.isDemoModeEnabled == false && isPreview == false else {
            self.contracts = [
                .dummyCourierOutstanding,
                .dummyCourierInProgress,
                .dummyCourierCompleted,
                .dummyCourierFailed,
                .dummyItemExchangeOutstanding,
                .dummyItemExchangeFinished
            ]
            self.loadingState = .ready
            return
        }
        
        if contracts.isEmpty {
            loadingState = .loading
        } else {
            loadingState = .reloading
        }
        
        guard let resource = source.resource else {
            return
        }
        
        do {
            self.contracts = (try await ECKWebService().loadResource(resource: resource)).response.reversed()
            loadingState = .ready
        } catch {
            logger.error("Error while fetching contracts \(error)")
            loadingState = .error
        }
    }
    
}
