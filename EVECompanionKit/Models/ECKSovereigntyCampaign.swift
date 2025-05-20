//
//  ECKSovereigntyCampaign.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 02.07.24.
//

import Foundation

public final class ECKSovereigntyCampaign: Decodable, ObservableObject, Identifiable, Equatable {
    
    enum CodingKeys: String, CodingKey {
        case attackersScore = "attackers_score"
        case campaignId = "campaign_id"
        case constellation = "constellation_id"
        case defenderId = "defender_id"
        case defenderScore = "defender_score"
        case eventType = "event_type"
        case solarSystem = "solar_system_id"
        case startTime = "start_time"
    }
    
    public enum EventType: String, Decodable {
        case tcuDefense = "tcu_defense"
        case ihubDefense = "ihub_defense"
        case stationDefense = "station_defense"
        case stationFreeport = "station_freeport"
        
        case unknown
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let stringValue = try container.decode(String.self)
            
            guard let value = EventType(rawValue: stringValue) else {
                logger.warning("Unknown asset sovereignty event type \(stringValue)")
                self = .unknown
                return
            }
            
            self = value
        }
    }
    
    public static let dummy: ECKSovereigntyCampaign = .init(attackersScore: nil,
                                                            campaignId: 1,
                                                            constellation: .init(constellationId: 20000696),
                                                            defendingAllianceId: 1354830081,
                                                            defendingAlliance: .init(name: "Goonswarm Federation",
                                                                                     ticker: "CONDI"),
                                                            defenderScore: 0.6,
                                                            eventType: .ihubDefense,
                                                            solarSystem: .init(solarSystemId: 30004759),
                                                            startTime: Date() + .fromSeconds(seconds: 25))
    
    @Published public var attackersScore: Float?
    public let campaignId: Int
    public let constellation: ECKConstellation
    public let defendingAllianceId: Int?
    @Published public var defendingAlliance: ECKAlliance?
    @Published public var defenderScore: Float?
    public let eventType: EventType
    public let solarSystem: ECKSolarSystem
    public let startTime: Date
    
    public var id: Int {
        return campaignId
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.attackersScore = try container.decodeIfPresent(Float.self, forKey: .attackersScore)
        self.campaignId = try container.decode(Int.self, forKey: .campaignId)
        self.constellation = try container.decode(ECKConstellation.self, forKey: .constellation)
        self.defendingAllianceId = try container.decodeIfPresent(Int.self, forKey: .defenderId)
        self.defenderScore = try container.decodeIfPresent(Float.self, forKey: .defenderScore)
        self.eventType = try container.decode(ECKSovereigntyCampaign.EventType.self, forKey: .eventType)
        self.solarSystem = try container.decode(ECKSolarSystem.self, forKey: .solarSystem)
        self.startTime = try container.decode(Date.self, forKey: .startTime)
    }
    
    public init(attackersScore: Float?,
                campaignId: Int,
                constellation: ECKConstellation,
                defendingAllianceId: Int?,
                defendingAlliance: ECKAlliance? = nil,
                defenderScore: Float?,
                eventType: EventType,
                solarSystem: ECKSolarSystem,
                startTime: Date) {
        self.attackersScore = attackersScore
        self.campaignId = campaignId
        self.constellation = constellation
        self.defendingAllianceId = defendingAllianceId
        self.defendingAlliance = defendingAlliance
        self.defenderScore = defenderScore
        self.eventType = eventType
        self.solarSystem = solarSystem
        self.startTime = startTime
    }
    
    public static func == (lhs: ECKSovereigntyCampaign,
                           rhs: ECKSovereigntyCampaign) -> Bool {
        return lhs.attackersScore == rhs.attackersScore &&
        lhs.campaignId == rhs.campaignId &&
        lhs.constellation.constellationId == rhs.constellation.constellationId &&
        lhs.defendingAllianceId == rhs.defendingAllianceId &&
        lhs.defenderScore == rhs.defenderScore &&
        lhs.eventType == rhs.eventType &&
        lhs.solarSystem.solarSystemId == rhs.solarSystem.solarSystemId &&
        lhs.startTime == rhs.startTime
    }
    
    func loadAllianceIfNecessary() {
        if let defendingAllianceId, defendingAlliance == nil {
            Task { @MainActor in
                self.defendingAlliance = await ECKAllianceManager.shared.get(allianceId: defendingAllianceId)
            }
        }
    }
    
}
