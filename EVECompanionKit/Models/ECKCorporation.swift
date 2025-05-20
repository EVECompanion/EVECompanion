//
//  ECKCorporation.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.24.
//

import Foundation

public class ECKCorporation: Decodable, ObservableObject {
    
    enum CodingKeys: String, CodingKey {
        case allianceId = "alliance_id"
        case ceoId = "ceo_id"
        case creatorId = "creator_id"
        case dateFounded = "date_founded"
        case description
        case factionId = "faction_id"
        case homeStationId = "home_station_id"
        case memberCount = "member_count"
        case name
        case shares
        case taxRate = "tax_rate"
        case ticker
        case url
        case warEligible = "war_eligible"
    }
    
    @Published public var alliance: ECKAlliance?
    let ceoId: Int
    let creatorId: Int
    public let dateFounded: Date?
    public let description: String?
    let factionId: Int?
    let homeStationId: Int?
    let memberCount: Int
    public let name: String
    let shares: Int?
    let taxRate: Float
    public let ticker: String
    let url: String?
    let warEligible: Bool?
    
    static let dummy: ECKCorporation = .init(allianceId: 498125261,
                                             ceoId: 94372731,
                                             creatorId: 94372731,
                                             dateFounded: .now - .fromDays(days: 600),
                                             description: "Dreddit is Recruiting!",
                                             factionId: nil,
                                             homeStationId: nil,
                                             memberCount: 1726,
                                             name: "Dreddit",
                                             shares: nil,
                                             taxRate: 0.08,
                                             ticker: "B0RT",
                                             url: "http://dredditisrecruiting.com",
                                             warEligible: true)
    
    static let `default`: ECKCorporation = .init(allianceId: nil,
                                                 ceoId: 0,
                                                 creatorId: 0,
                                                 dateFounded: nil,
                                                 description: nil,
                                                 factionId: nil,
                                                 homeStationId: nil,
                                                 memberCount: 0,
                                                 name: "Unknown",
                                                 shares: nil,
                                                 taxRate: 0,
                                                 ticker: "",
                                                 url: nil,
                                                 warEligible: nil)
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.ceoId = try container.decode(Int.self, forKey: .ceoId)
        self.creatorId = try container.decode(Int.self, forKey: .creatorId)
        self.dateFounded = try container.decodeIfPresent(Date.self, forKey: .dateFounded)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.factionId = try container.decodeIfPresent(Int.self, forKey: .factionId)
        self.homeStationId = try container.decodeIfPresent(Int.self, forKey: .homeStationId)
        self.memberCount = try container.decode(Int.self, forKey: .memberCount)
        self.name = try container.decode(String.self, forKey: .name)
        self.shares = try container.decodeIfPresent(Int.self, forKey: .shares)
        self.taxRate = try container.decode(Float.self, forKey: .taxRate)
        self.ticker = try container.decode(String.self, forKey: .ticker)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.warEligible = try container.decodeIfPresent(Bool.self, forKey: .warEligible)
        
        if let allianceId = try container.decodeIfPresent(Int.self, forKey: .allianceId) {
            Task { @MainActor in
                self.alliance = await ECKAllianceManager.shared.get(allianceId: allianceId)
            }
        } else {
            self.alliance = nil
        }
    }
    
    init(allianceId: Int?, 
         ceoId: Int,
         creatorId: Int,
         dateFounded: Date?,
         description: String?,
         factionId: Int?,
         homeStationId: Int?,
         memberCount: Int,
         name: String,
         shares: Int?,
         taxRate: Float,
         ticker: String,
         url: String?,
         warEligible: Bool?) {
        self.alliance = .dummy
        self.ceoId = ceoId
        self.creatorId = creatorId
        self.dateFounded = dateFounded
        self.description = description
        self.factionId = factionId
        self.homeStationId = homeStationId
        self.memberCount = memberCount
        self.name = name
        self.shares = shares
        self.taxRate = taxRate
        self.ticker = ticker
        self.url = url
        self.warEligible = warEligible
    }
    
}
