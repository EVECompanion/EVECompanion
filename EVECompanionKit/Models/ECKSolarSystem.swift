//
//  ECKSolarSystem.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 13.05.24.
//

import Foundation
public import Combine
import simd

public final class ECKSolarSystem: Codable, Identifiable, Hashable, ObservableObject, @unchecked Sendable {
    
    public var id: Int {
        return solarSystemId
    }
    
    let solarSystemId: Int
    public let constellationId: Int
    public let region: ECKRegion
    public let solarSystemName: String
    public let security: Double
    
    public let position: SIMD3<Float>
    public let position2D: SIMD2<Float>?
    public let sunTypeId: Int?
    
    @Published public var sovereignty: ECKSolarSystemSovereignty?

    public var sovereigntyLogoSource: ECKSolarSystemImageSource? {
        sovereignty?.logoSource
    }

    public var primaryImageSource: ECKSolarSystemImageSource? {
        sovereigntyLogoSource ?? sunTypeId.map { ECKSolarSystemImageSource(id: $0, category: .types) }
    }
    
    private var subscriptions = Set<AnyCancellable>()
    
    static let jita: ECKSolarSystem = .init(solarSystemId: 30000142)
    
    public required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let solarSystemId = try container.decode(Int.self)
        self.init(solarSystemId: solarSystemId)
    }
    
    public required convenience init(solarSystemId: Int) {
        let solarSystemData = ECKSDEManager.shared.getSolarSystem(solarSystemId: solarSystemId)
        self.init(fetchedSolarSystem: solarSystemData)
    }
    
    init(fetchedSolarSystem: ECKSDEManager.FetchedSolarSystem) {
        self.solarSystemId = fetchedSolarSystem.solarSystemId
        self.constellationId = fetchedSolarSystem.constellationId
        self.region = .init(regionId: fetchedSolarSystem.regionId)
        self.solarSystemName = fetchedSolarSystem.solarSystemName
        self.security = fetchedSolarSystem.security
        self.position = SIMD3(x: fetchedSolarSystem.x,
                              y: fetchedSolarSystem.y,
                              z: fetchedSolarSystem.z)
        if let position2Dx = fetchedSolarSystem.position2Dx, let position2Dy = fetchedSolarSystem.position2Dy {
            self.position2D = SIMD2(position2Dx, position2Dy)
        } else {
            self.position2D = nil
        }
        self.sunTypeId = fetchedSolarSystem.sunTypeId
        
        Task { @MainActor in
            subscriptions.forEach({ $0.cancel() })
            let sov = await ECKSovereigntyManager.shared.sov(for: self)
            sov?.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] _ in
                    self?.objectWillChange.send()
                })
                .store(in: &subscriptions)
            self.sovereignty = sov
        }
    }
    
    public static func == (lhs: ECKSolarSystem, rhs: ECKSolarSystem) -> Bool {
        return lhs.solarSystemId == rhs.solarSystemId
        && lhs.constellationId == rhs.constellationId
        && lhs.region == rhs.region
        && lhs.solarSystemName == rhs.solarSystemName
        && lhs.security == rhs.security
        && lhs.position == rhs.position
        && lhs.sunTypeId == rhs.sunTypeId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(solarSystemId)
        hasher.combine(constellationId)
        hasher.combine(region)
        hasher.combine(solarSystemName)
        hasher.combine(security)
        hasher.combine(position)
        hasher.combine(sunTypeId)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(solarSystemId)
    }
    
    public func distance(to system: ECKSolarSystem) -> Double {
        return Double(simd_distance(position, system.position))
    }
    
}
