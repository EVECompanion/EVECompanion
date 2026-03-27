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
    
    @Published public var marketOrders: [ECKMarketOrder]?
    @Published public var marketOrdersLoadingState: ECKLoadingState = .loading
    
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
    
    public static let dummy: ECKAuthenticatedCorporation = .init()
    
    internal init(token: ECKToken) {
        self.authenticatingCharacter = .init(token: token, dataLoadingTarget: .corp)
    }
    
    private init() {
        self.authenticatingCharacter = .dummy
        self.marketOrders = [.dummy1, .dummy2]
        self.marketOrdersLoadingState = .ready
    }
    
    @MainActor
    public func loadMarketOrders() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            marketOrdersLoadingState = .ready
            return
        }
        
        guard let corpId else {
            return
        }
        
        if marketOrders != nil {
            marketOrdersLoadingState = .reloading
        } else {
            marketOrdersLoadingState = .loading
        }
        
        // TODO: Paging
        let resource = ECKCorporationMarketOrdersResource(
            corporationId: corpId,
            page: 1,
            token: authenticatingCharacter.token
        )
        do {
            self.marketOrders = try await ECKWebService().loadResource(resource: resource).response.sorted(by: { $0.item.name < $1.item.name })
            self.marketOrdersLoadingState = .ready
        } catch {
            logger.error("Error loading loyalty points: \(String(describing: error))")
            self.marketOrdersLoadingState = .error
        }
    }
    
    public static func == (lhs: ECKAuthenticatedCorporation, rhs: ECKAuthenticatedCorporation) -> Bool {
        return lhs.authenticatingCharacter == rhs.authenticatingCharacter
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(authenticatingCharacter)
    }
    
}
