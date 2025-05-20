//
//  ECKSolarSystemSovereignty.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 21.03.25.
//

public import Combine

public class ECKSolarSystemSovereignty: Decodable, ObservableObject, Equatable {
    
    private enum CodingKeys: String, CodingKey {
        case allianceId = "alliance_id"
        case faction = "faction_id"
        case systemId = "system_id"
    }
    
    public let allianceId: Int?
    public let faction: ECKFaction?
    let systemId: Int
    
    @Published public var alliance: ECKAlliance?
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.allianceId = try container.decodeIfPresent(Int.self, forKey: .allianceId)
        self.faction = try container.decodeIfPresent(ECKFaction.self, forKey: .faction)
        self.systemId = try container.decode(Int.self, forKey: .systemId)
        loadData()
    }
    
    init(allianceId: Int?,
         corporationId: Int?,
         factionId: Int?,
         systemId: Int) {
        self.allianceId = allianceId
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
        && lhs.faction == rhs.faction
        && lhs.systemId == rhs.systemId
        && lhs.alliance == rhs.alliance
    }
    
}
