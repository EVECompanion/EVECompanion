//
//  ECKLoyaltyPointsEntry.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.24.
//

import Foundation

public class ECKLoyaltyPointsEntry: Decodable, ObservableObject, Identifiable {
    
    enum CodingKeys: String, CodingKey {
        case corporationId = "corporation_id"
        case loyaltyPoints = "loyalty_points"
    }
    
    public let id = UUID()
    @Published public var corporation: ECKCorporation?
    public let loyaltyPoints: Int
    public let corporationId: Int
    
    public static let dummy1: ECKLoyaltyPointsEntry = .init(corporationId: 1000035,
                                                            loyaltyPoints: 500)
    
    public static let dummy2: ECKLoyaltyPointsEntry = .init(corporationId: 1000051,
                                                            loyaltyPoints: 360)
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.corporationId = try container.decode(Int.self, forKey: .corporationId)
        self.loyaltyPoints = try container.decode(Int.self, forKey: .loyaltyPoints)
        loadCorporationData()
    }
    
    init(corporationId: Int, loyaltyPoints: Int) {
        self.corporationId = corporationId
        self.loyaltyPoints = loyaltyPoints
        loadCorporationData()
    }
    
    private func loadCorporationData() {
        Task { @MainActor in
            let resource = ECKCorporationResource(corporationId: corporationId)
            do {
                self.corporation = try await ECKWebService().loadResource(resource: resource).response
            } catch {
                logger.error("Error loading corporation data \(error)")
                self.corporation = .default
            }
        }
    }
    
}
