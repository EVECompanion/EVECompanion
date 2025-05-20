//
//  ECKContractManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 11.05.24.
//

public import Combine

public class ECKContractManager: ObservableObject {
    
    public let character: ECKCharacter
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
    
    public init(character: ECKCharacter, isPreview: Bool = false) {
        self.character = character
        self.isPreview = isPreview
        Task {
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
        
        let resource = ECKCharacterContractResource(token: character.token)
        do {
            self.contracts = (try await ECKWebService().loadResource(resource: resource)).response.reversed()
            loadingState = .ready
        } catch {
            logger.error("Error while fetching contracts \(error)")
            loadingState = .error
        }
    }
    
}
