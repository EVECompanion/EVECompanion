//
//  ECKSearchResponse.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 17.05.26.
//

import Foundation

struct ECKSearchResponse: Decodable, Sendable {
    
    let agent: [Int]?
    let alliance: [Int]?
    let character: [Int]?
    let constellation: [Int]?
    let corporation: [Int]?
    let faction: [Int]?
    let inventoryType: [Int]?
    let region: [Int]?
    let solarSystem: [Int]?
    let station: [Int]?
    let structure: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case agent
        case alliance
        case character
        case constellation
        case corporation
        case faction
        case inventoryType = "inventory_type"
        case region
        case solarSystem = "solar_system"
        case station
        case structure
    }
    
    func ids(for category: ECKSearchCategory) -> [Int] {
        switch category {
        case .agent:
            agent ?? []
        case .alliance:
            alliance ?? []
        case .character:
            character ?? []
        case .constellation:
            constellation ?? []
        case .corporation:
            corporation ?? []
        case .faction:
            faction ?? []
        case .inventoryType:
            inventoryType ?? []
        case .region:
            region ?? []
        case .solarSystem:
            solarSystem ?? []
        case .station:
            station ?? []
        case .structure:
            structure ?? []
        }
    }
    
    var mailRecipients: [ECKMailRecipient] {
        var recipients = [ECKMailRecipient]()
        
        recipients.append(contentsOf: ids(for: .character).map({
            ECKMailRecipient(recipientId: $0,
                             recipientType: .character)
        }))
        recipients.append(contentsOf: ids(for: .corporation).map({
            ECKMailRecipient(recipientId: $0,
                             recipientType: .corporation)
        }))
        recipients.append(contentsOf: ids(for: .alliance).map({
            ECKMailRecipient(recipientId: $0,
                             recipientType: .alliance)
        }))
        
        return recipients
    }
}
