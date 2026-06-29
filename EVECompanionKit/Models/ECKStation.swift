//
//  ECKStation.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 13.05.24.
//

public import Combine

public class ECKStation: ObservableObject, Decodable, Identifiable, Equatable, @unchecked Sendable {
    
    let stationId: Int
    let token: ECKToken?

    public var id: Int {
        stationId
    }

    @Published public var solarSystem: ECKSolarSystem?
    @Published public var stationName: String?
    @Published public var typeId: Int?
    public let isStructure: Bool

    public var imageSource: ECKSolarSystemImageSource? {
        typeId.map { ECKSolarSystemImageSource(id: $0, category: .types) }
    }
    
    static let unknown: ECKStation = .init()
    static let jita: ECKStation = .init(stationId: 60003760, token: .dummy)
    
    private init() {
        self.stationId = 0
        self.token = .dummy
        self.stationName = "Unknown Station"
        self.isStructure = false
    }
    
    public required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stationId = try container.decode(Int.self)
        let token = decoder.userInfo[ECKWebService.tokenCodingUserInfoKey] as? ECKToken
        self.init(stationId: stationId, token: token)
    }
    
    init(stationId: Int, token: ECKToken?) {
        self.stationId = stationId
        self.token = token
        if stationId > 1000000000000 {
            // This is a structure, not a station.
            self.isStructure = true
            Task {
                await loadStructureData()
            }
        } else {
            let stationData = ECKSDEManager.shared.getStation(stationId: stationId)
            self.solarSystem = .init(solarSystemId: stationData.solarSystemId)
            self.stationName = stationData.stationName
            self.typeId = stationData.typeId
            self.isStructure = false
        }
    }

    init(stationData: ECKSDEManager.FetchedStation, token: ECKToken?) {
        self.stationId = stationData.stationId
        self.token = token
        self.solarSystem = .init(solarSystemId: stationData.solarSystemId)
        self.stationName = stationData.stationName
        self.typeId = stationData.typeId
        self.isStructure = false
    }
    
    @MainActor
    func loadStructureData() async {
        guard let token else {
            self.solarSystem = nil
            self.stationName = "Unknown Structure"
            return
        }
        
        guard let structure = await ECKStructureCache.shared.get(structureId: stationId, using: token) else {
            self.solarSystem = nil
            self.stationName = "Unknown Structure"
            return
        }
        
        self.solarSystem = .init(solarSystemId: structure.solarSystemId)
        self.typeId = structure.typeId
        self.stationName = structure.name
    }

    public static func == (lhs: ECKStation, rhs: ECKStation) -> Bool {
        lhs.stationId == rhs.stationId
        && lhs.solarSystem == rhs.solarSystem
        && lhs.stationName == rhs.stationName
        && lhs.typeId == rhs.typeId
        && lhs.isStructure == rhs.isStructure
    }
    
}
