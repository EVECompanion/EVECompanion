//
//  ECKAuthenticatedCorporation.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 22.11.25.
//

import Foundation

public class ECKAuthenticatedCorporation: ObservableObject, Identifiable, Hashable {
    
    @NestedObservableObject public var authenticatingCharacter: ECKCharacter
    
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
    }
    
    public static func == (lhs: ECKAuthenticatedCorporation, rhs: ECKAuthenticatedCorporation) -> Bool {
        return lhs.authenticatingCharacter == rhs.authenticatingCharacter
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(authenticatingCharacter)
    }
    
}
