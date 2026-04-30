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
    @Published public var divisions: ECKCorporationDivisionsResponse?
    @Published public var divisionsLoadingState: ECKLoadingState = .loading
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
    
    @MainActor
    public private(set) var walletDivisionsLoadingTask: Task<Void, Never>?
    
    public static let dummy: ECKAuthenticatedCorporation = .init()
    
    internal init(token: ECKToken) {
        self.authenticatingCharacter = .init(token: token, dataLoadingTarget: .corp)
        
        Task {
            await loadInitialData()
        }
    }
    
    private init() {
        self.authenticatingCharacter = .dummy
        self.divisions = .init(
            hangar: [
                .init(division: 1, name: "Main Hangar"),
                .init(division: 2, name: "Industry"),
                .init(division: 3, name: "Logistics"),
                .init(division: 4, name: "SRP"),
                .init(division: 5, name: "Trading"),
                .init(division: 6, name: "Reserve"),
                .init(division: 7, name: "Overflow")
            ],
            wallet: [
                .init(division: 1, name: "Master Wallet"),
                .init(division: 2, name: "Operations"),
                .init(division: 3, name: "Industry"),
                .init(division: 4, name: "SRP"),
                .init(division: 5, name: "Logistics"),
                .init(division: 6, name: "Trading"),
                .init(division: 7, name: "Reserve")
            ]
        )
        self.divisionsLoadingState = .ready
        self.walletDivisions = [
            .init(division: 1, balance: 4250000000, name: "Master Wallet"),
            .init(division: 2, balance: 980000000, name: "Operations"),
            .init(division: 3, balance: 120500000, name: "Industry"),
            .init(division: 4, balance: 0, name: "SRP"),
            .init(division: 5, balance: 754000000, name: "Logistics"),
            .init(division: 6, balance: 24500000, name: "Trading"),
            .init(division: 7, balance: 1300000, name: "Reserve")
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
    public func loadInitialData() async {
        authenticatingCharacter.loadInitialCorpData()
        await authenticatingCharacter.initialDataLoadingTask?.value
        await loadDivisions()
        await loadWalletDivisions()
    }
    
    @MainActor
    public func loadDivisions() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            divisionsLoadingState = .ready
            return
        }
        
        guard let corporationId = corpId else {
            divisionsLoadingState = .error(.unknownError)
            return
        }
        
        guard let roles else {
            divisionsLoadingState = .error(.unknownError)
            return
        }
        
        divisionsLoadingState = .loading
        
        let divisionsResource = ECKCorporationDivisionsResource(
            corporationId: corporationId,
            token: authenticatingCharacter.token,
            currentRoles: roles
        )
        
        do {
            self.divisions = try await ECKWebService()
                .loadResource(resource: divisionsResource)
                .response
            self.divisionsLoadingState = .ready
        } catch let error {
            logger.error("Error loading corporation divisions data: \(String(describing: error))")
            self.divisionsLoadingState = .error(error)
        }
    }
    
    @MainActor
    public func loadWalletDivisions() async {
        walletDivisionsLoadingTask = Task<Void, Never> {
            defer {
                walletDivisionsLoadingTask = nil
            }
            
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
            let walletResource = ECKCorporationWalletsResource(
                corporationId: corporationId,
                token: authenticatingCharacter.token,
                currentRoles: roles
            )
            
            do {
                let walletBalances = try await ECKWebService()
                    .loadResource(resource: walletResource)
                    .response
                let walletDivisionNames: [Int: String] = (divisions?.wallet ?? []).reduce(into: [:]) { result, division in
                    guard let name = division.name,
                          name.isEmpty == false else {
                        return
                    }
                    
                    result[division.division] = name
                }
                
                self.walletDivisions = walletBalances
                    .map { division in
                        ECKCorporationWalletDivision(
                            division: division.division,
                            balance: division.balance,
                            name: walletDivisionNames[division.division] ?? division.name
                        )
                    }
                    .sorted(by: { $0.division < $1.division })
                self.walletDivisionsLoadingState = .ready
            } catch let error as ECKWebError {
                logger.error("Error loading corporation wallet data: \(String(describing: error))")
                self.walletDivisionsLoadingState = .error(error)
            } catch {
                logger.error("Error loading corporation wallet data: \(String(describing: error))")
                self.walletDivisionsLoadingState = .error(.unknownError)
            }
        }
    }
    
}
