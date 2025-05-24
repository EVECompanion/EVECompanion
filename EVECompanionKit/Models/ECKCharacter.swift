//
//  ECKCharacter.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.05.24.
//

import Foundation
public import Combine

public class ECKCharacter: ObservableObject, Identifiable, Hashable {
    
    internal let token: ECKToken
    
    public var id: Int {
        return token.characterId
    }
    
    public var name: String {
        return token.characterName
    }
    
    @Published public var wallet: Double?
    @Published public var attributes: ECKCharacterAttributes?
    @Published public var implants: [ECKItem]?
    @Published public var skills: ECKCharacterSkills?
    @Published public var skillqueue: ECKCharacterSkillQueue?
    @Published public var publicInfo: ECKPublicCharacterInfo?
    @Published public var mailbox: [ECKMail]?
    @Published public var corporation: ECKCorporation?
    @Published public var alliance: ECKAlliance?
    @Published public var walletJournal: [ECKWalletJournalEntry]?
    @Published public var walletTransactions: [ECKWalletTransactionEntry]?
    @Published public var loyaltyPoints: [ECKLoyaltyPointsEntry]?
    @Published public var marketOrders: [ECKMarketOrder]?
    @Published public var jumpFatigue: ECKJumpFatigue?
    
    @Published public var initialDataLoadingState: ECKLoadingState = .loading
    @Published public var walletJournalLoadingState: ECKLoadingState = .loading
    @Published public var walletTransactionsLoadingState: ECKLoadingState = .loading
    @Published public var marketOrdersLoadingState: ECKLoadingState = .loading
    
    public var hasValidToken: Bool {
        return token.isValid
    }
    
    static public let dummy: ECKCharacter = .init()
    
    internal init(token: ECKToken) {
        self.token = token
        Task { @MainActor in
            loadInitialData()
        }
        
    }
    
    @MainActor
    public private(set) var initialDataLoadingTask: Task<Void, Never>?
    
    private init() {
        self.token = .dummy
        self.wallet = 15500000000
        self.skills = .dummy
        self.skillqueue = .dummy
        self.publicInfo = .dummy
        self.mailbox = [.dummyRead, .dummyUnread]
        self.walletJournal = [.dummy1, .dummy2, .dummy3]
        self.walletTransactions = [.dummy1, .dummy2]
        self.loyaltyPoints = [.dummy1, .dummy2]
        self.corporation = .dummy
        self.alliance = .dummy
        self.attributes = .dummy
        self.marketOrders = [.dummy1, .dummy2]
        self.jumpFatigue = .dummy
        self.initialDataLoadingState = .ready
        self.marketOrdersLoadingState = .ready
    }
    
    @MainActor
    public func loadInitialData() {
        initialDataLoadingTask = Task { @MainActor in
            self.initialDataLoadingState = .loading
            
            do {
                
                let walletResource = ECKCharacterWalletResource(token: token)
                async let wallet = try ECKWebService().loadResource(resource: walletResource).response
                
                let skillsResource = ECKCharacterSkillsResource(token: token)
                async let skillsResponse = try ECKWebService().loadResource(resource: skillsResource).response
                
                let skillqueueResourcce = ECKCharacterSkillqueueResource(token: token)
                async let skillqueueResponse = try ECKWebService().loadResource(resource: skillqueueResourcce).response
                
                let publicInfoResource = ECKPublicCharacterInfoResource(token: token)
                async let publicInfoResponse = try ECKWebService().loadResource(resource: publicInfoResource).response
                
                let mailboxResource = ECKFetchMailResource(token: token,
                                                           lastMailId: nil)
                async let mailboxResponse = try ECKWebService().loadResource(resource: mailboxResource).response
                
                (self.wallet,
                 self.skills,
                 self.skillqueue,
                 self.publicInfo,
                 self.mailbox) = await (try? wallet,
                                        try? skillsResponse,
                                        try? skillqueueResponse,
                                        try? publicInfoResponse,
                                        try? mailboxResponse)
                if let skillqueue {
                    self.skills?.updateWithSkillQueue(skillqueue)
                }
                self.initialDataLoadingState = .ready
            } catch {
                logger.error("Error loading data: \(error)")
                self.initialDataLoadingState = .error
            }
        }
    }
    
    @MainActor
    public func reloadSkillQueue() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            return
        }
        
        let skillqueueResource = ECKCharacterSkillqueueResource(token: token)
        let skillqueueResponse = try? await ECKWebService().loadResource(resource: skillqueueResource).response
        
        guard let skillqueueResponse else {
            return
        }
        
        if let skills {
            skills.updateWithSkillQueue(skillqueueResponse)
        }
        
        self.skillqueue = skillqueueResponse
    }
    
    @MainActor
    public func reloadSkills() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            return
        }
        
        let skillsResource = ECKCharacterSkillsResource(token: token)
        let skillsResponse = try? await ECKWebService().loadResource(resource: skillsResource).response
        if let skillqueue {
            skillsResponse?.updateWithSkillQueue(skillqueue)
        }
        self.skills = skillsResponse
    }
    
    @MainActor 
    public func remove() {
        ECKKeychain.remove(token: token)
    }
    
    @MainActor
    public func loadSheetData() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            return
        }
        
        // Update all the other data
        loadInitialData()
        
        if let allianceId = publicInfo?.allianceId {
            Task { @MainActor in
                self.alliance = await ECKAllianceManager.shared.get(allianceId: allianceId)
            }
        }
        
        if let corporationId = publicInfo?.corporationId {
            Task { @MainActor in
                let corporationResource = ECKCorporationResource(corporationId: corporationId)
                let corporationResponse = try? await ECKWebService().loadResource(resource: corporationResource).response
                self.corporation = corporationResponse
            }
        }
        
        Task { @MainActor in
            await self.loadAttributes()
        }
        
        Task { @MainActor in
            await self.loadImplants()
        }
        
        Task { @MainActor in
            await self.loadJumpFatigue()
        }
    }
    
    @MainActor
    public func loadWalletJournal() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            return
        }
        
        walletJournalLoadingState = .loading
        let resource = ECKCharacterWalletJournalResource(token: token)
        do {
            self.walletJournal = try await ECKWebService().loadResource(resource: resource).response
            walletJournalLoadingState = .ready
        } catch {
            logger.error("Error loading wallet journal data: \(String(describing: error))")
            walletJournalLoadingState = .error
        }
    }
    
    @MainActor
    public func loadWalletTransactions() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            return
        }
        
        self.walletTransactionsLoadingState = .loading
        let resource = ECKCharacterWalletTransactionResource(token: token)
        do {
            self.walletTransactions = try await ECKWebService().loadResource(resource: resource).response
            self.walletTransactionsLoadingState = .ready
        } catch {
            logger.error("Error loading wallet transaction data: \(String(describing: error))")
            self.walletTransactionsLoadingState = .error
        }
    }
    
    @MainActor
    public func loadAttributes() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            return
        }
        
        let resource = ECKCharacterAttributesResource(token: token)
        do {
            self.attributes = try await ECKWebService().loadResource(resource: resource).response
        } catch {
            logger.error("Error loading attribute data: \(String(describing: error))")
        }
    }
    
    @MainActor
    public func loadImplants() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            return
        }
        
        let resource = ECKCharacterImplantResource(token: token)
        do {
            self.implants = try await ECKWebService().loadResource(resource: resource).response
        } catch {
            logger.error("Error loading implant data: \(String(describing: error))")
        }
    }
    
    @MainActor
    public func loadLoyaltyPoints() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            return
        }
        
        let resource = ECKLoyaltyPointsResource(token: token)
        do {
            self.loyaltyPoints = try await ECKWebService().loadResource(resource: resource).response
        } catch {
            logger.error("Error loading loyalty points: \(String(describing: error))")
        }
    }
    
    @MainActor
    public func loadJumpFatigue() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            return
        }
        
        let resource = ECKCharacterJumpFatigueResource(token: token)
        do {
            self.jumpFatigue = try await ECKWebService().loadResource(resource: resource).response
        } catch {
            logger.error("Error loading jump fatigue: \(String(describing: error))")
        }
    }
    
    @MainActor
    public func loadMarketOrders() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            marketOrdersLoadingState = .ready
            return
        }
        
        if marketOrders != nil {
            marketOrdersLoadingState = .reloading
        } else {
            marketOrdersLoadingState = .loading
        }
        
        let resource = ECKCharacterMarketOrdersResource(token: token)
        do {
            self.marketOrders = try await ECKWebService().loadResource(resource: resource).response.sorted(by: { $0.item.name < $1.item.name })
            self.marketOrdersLoadingState = .ready
        } catch {
            logger.error("Error loading loyalty points: \(String(describing: error))")
            self.marketOrdersLoadingState = .error
        }
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: ECKCharacter, rhs: ECKCharacter) -> Bool {
        return lhs.token == rhs.token
            && lhs.wallet == rhs.wallet
            && lhs.skills == rhs.skills
            && lhs.skillqueue == rhs.skillqueue
            && lhs.publicInfo == rhs.publicInfo
    }
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(token)
        hasher.combine(wallet)
        hasher.combine(skills)
        hasher.combine(skillqueue)
        hasher.combine(publicInfo)
    }
    
}
