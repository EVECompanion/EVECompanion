//
//  ECKAuthenticatedCorporation.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 22.11.25.
//

import Foundation
public import Combine

public final class ECKAuthenticatedCorporation: ObservableObject, Identifiable, Hashable, @unchecked Sendable {
    
    @NestedObservableObject public var authenticatingCharacter: ECKCharacter
    @Published public var walletDivisions: [ECKCorporationWalletDivision]?
    @Published public var walletDivisionsLoadingState: ECKLoadingState = .loading
    
    public var corpId: Int? {
        authenticatingCharacter.publicInfo?.corporationId
    }
    
    public var publicCorpInfo: ECKCorporation? {
        return authenticatingCharacter.corporation
    }
    
    public var allianceId: Int? {
        authenticatingCharacter.publicInfo?.allianceId
    }
    
    public var publicAllianceInfo: ECKAlliance? {
        return authenticatingCharacter.alliance
    }
    
    public var roles: [ECKCorporationRole]? {
        return authenticatingCharacter.corpRoles?.roles
    }
    
    public static let dummy: ECKAuthenticatedCorporation = .init()
    
    internal init(token: ECKToken) {
        self.authenticatingCharacter = .init(token: token, dataLoadingTarget: .corp)
        
        Task {
            await authenticatingCharacter.initialDataLoadingTask?.value
            await loadWalletDivisions()
        }
    }
    
    private init() {
        self.authenticatingCharacter = .dummy
        self.walletDivisions = [
            .init(division: 1, balance: 4250000000),
            .init(division: 2, balance: 980000000),
            .init(division: 3, balance: 120500000),
            .init(division: 4, balance: 0),
            .init(division: 5, balance: 754000000),
            .init(division: 6, balance: 24500000),
            .init(division: 7, balance: 1300000)
        ]
        self.walletDivisionsLoadingState = .ready
    }
    
    public static func == (lhs: ECKAuthenticatedCorporation, rhs: ECKAuthenticatedCorporation) -> Bool {
        return lhs.authenticatingCharacter == rhs.authenticatingCharacter
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(authenticatingCharacter)
    }
    
    @MainActor
    public func loadWalletDivisions() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            walletDivisionsLoadingState = .ready
            return
        }
        
        guard let corporationId = corpId else {
            walletDivisionsLoadingState = .error(.unknownError)
            return
        }
        
        guard let roles else {
            walletDivisionsLoadingState = .error(.unknownError)
            return
        }
        
        await authenticatingCharacter.initialDataLoadingTask?.value
        
        walletDivisionsLoadingState = .loading
        let resource = ECKCorporationWalletsResource(
            corporationId: corporationId,
            token: authenticatingCharacter.token,
            currentRoles: roles
        )
        
        do {
            self.walletDivisions = try await ECKWebService()
                .loadResource(resource: resource)
                .response
                .sorted(by: { $0.division < $1.division })
            self.walletDivisionsLoadingState = .ready
        } catch let error {
            logger.error("Error loading corporation wallet data: \(String(describing: error))")
            self.walletDivisionsLoadingState = .error(error)
        }
    }
    
}
