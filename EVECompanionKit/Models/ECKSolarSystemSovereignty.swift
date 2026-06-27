//
//  ECKSolarSystemSovereignty.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 21.03.25.
//

public import Combine

public class ECKSolarSystemSovereignty: Decodable, ObservableObject, Equatable, @unchecked Sendable {
    
    private enum CodingKeys: String, CodingKey {
        case allianceId = "alliance_id"
        case corporationId = "corporation_id"
        case faction = "faction_id"
        case systemId = "system_id"
    }
    
    public let allianceId: Int?
    public let corporationId: Int?
    public let faction: ECKFaction?
    let systemId: Int
    
    @Published public var alliance: ECKAlliance?

    public var displayName: String? {
        if let alliance {
            return "\(alliance.name) [\(alliance.ticker)]"
        }

        if let faction {
            return faction.name
        }

        if let allianceId {
            return "Alliance ID \(allianceId)"
        }

        if let corporationId {
            return "Corporation ID \(corporationId)"
        }

        return nil
    }

    public var logoSource: ECKSolarSystemImageSource? {
        if let allianceId {
            return .init(id: allianceId, category: .alliance)
        }

        if let corporationId {
            return .init(id: corporationId, category: .corporation)
        }

        if let faction {
            return .init(id: faction.factionId, category: .corporation)
        }

        return nil
    }
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.allianceId = try container.decodeIfPresent(Int.self, forKey: .allianceId)
        self.corporationId = try container.decodeIfPresent(Int.self, forKey: .corporationId)
        self.faction = try container.decodeIfPresent(ECKFaction.self, forKey: .faction)
        self.systemId = try container.decode(Int.self, forKey: .systemId)
        loadData()
    }
    
    init(allianceId: Int?,
         corporationId: Int?,
         factionId: Int?,
         systemId: Int) {
        self.allianceId = allianceId
        self.corporationId = corporationId
        if let factionId = factionId {
            self.faction = .init(factionId: factionId)
        } else {
            self.faction = nil
        }
        self.systemId = systemId
        loadData()
    }
    
    private func loadData() {
        Task {
            await loadAlliance()
        }
    }
    
    @MainActor
    private func loadAlliance() async {
        if let allianceId = allianceId {
            self.alliance = await ECKAllianceManager.shared.get(allianceId: allianceId)
        } else {
            self.alliance = nil
        }
    }
    
    public static func == (lhs: ECKSolarSystemSovereignty, rhs: ECKSolarSystemSovereignty) -> Bool {
        return lhs.allianceId == rhs.allianceId
        && lhs.corporationId == rhs.corporationId
        && lhs.faction == rhs.faction
        && lhs.systemId == rhs.systemId
        && lhs.alliance == rhs.alliance
    }
    
}
