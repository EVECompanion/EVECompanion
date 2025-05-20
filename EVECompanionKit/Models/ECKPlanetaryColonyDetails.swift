//
//  ECKPlanetaryColonyDetails.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.10.24.
//

import Foundation

public class ECKPlanetaryColonyDetails: Decodable {
    
    enum CodingKeys: CodingKey {
        case links
        case pins
        case routes
    }
    
    public enum Warning {
        case extractionExpiresSoon
        case extractionExpired
        case storageRunningFull
    }
    
    public lazy var warnings: Set<Warning> = {
        var result = Set<Warning>()
        
        for pin in pins {
            result.formUnion(pin.warnings)
        }
        
        return result
    }()
    
    public let links: [ECKPlanetaryColonyLink]
    public let pins: [ECKPlanetaryColonyPin]
    public let routes: [ECKPlanetaryColonyRoute]
    
    public static let dummy1: ECKPlanetaryColonyDetails = .init(links: [.dummy1, .dummy2, .dummy3, .dummy4],
                                                                pins: [.dummy1, .dummy2, .dummy3, .dummy4],
                                                                routes: [.dummy1, .dummy2, .dummy3])
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.links = try container.decode([ECKPlanetaryColonyLink].self, forKey: .links)
        let pinComparator = KeyPathComparator(\ECKPlanetaryColonyPin.pinType.rawValue)
        self.pins = try container.decode([ECKPlanetaryColonyPin].self, forKey: .pins).sorted(using: pinComparator)
        self.routes = try container.decode([ECKPlanetaryColonyRoute].self, forKey: .routes)
    }
    
    init(links: [ECKPlanetaryColonyLink],
         pins: [ECKPlanetaryColonyPin],
         routes: [ECKPlanetaryColonyRoute]) {
        self.links = links
        self.pins = pins
        self.routes = routes
    }
    
}

public class ECKPlanetaryColonyLink: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case destinationPinId = "destination_pin_id"
        case linkLevel = "link_level"
        case sourcePinId = "source_pin_id"
    }
    
    public let destinationPinId: Int
    public let linkLevel: Int
    public let sourcePinId: Int
    
    static let dummy1: ECKPlanetaryColonyLink = .init(destinationPinId: 1045690691222,
                                                      linkLevel: 0,
                                                      sourcePinId: 1045690545611)
    
    static let dummy2: ECKPlanetaryColonyLink = .init(destinationPinId: 1045690691233,
                                                      linkLevel: 0,
                                                      sourcePinId: 1045690691229)
    
    static let dummy3: ECKPlanetaryColonyLink = .init(destinationPinId: 1045690691229,
                                                      linkLevel: 0,
                                                      sourcePinId: 1045690691222)
    
    static let dummy4: ECKPlanetaryColonyLink = .init(destinationPinId: 1045690575739,
                                                      linkLevel: 0,
                                                      sourcePinId: 1045690545611)
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.destinationPinId = try container.decode(Int.self, forKey: .destinationPinId)
        self.linkLevel = try container.decode(Int.self, forKey: .linkLevel)
        self.sourcePinId = try container.decode(Int.self, forKey: .sourcePinId)
    }
    
    init(destinationPinId: Int,
         linkLevel: Int,
         sourcePinId: Int) {
        self.destinationPinId = destinationPinId
        self.linkLevel = linkLevel
        self.sourcePinId = sourcePinId
    }
    
}

public class ECKPlanetaryColonyRoute: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case contentTypeId = "content_type_id"
        case destinationPinId = "destination_pin_id"
        case quantity
        case routeId = "route_id"
        case sourcePinId = "source_pin_id"
        case waypoints
    }
    
    public let contentTypeId: Int
    public let destinationPinId: Int
    public let quantity: Float
    public let routeId: Int
    public let sourcePinId: Int
    public let waypoints: [Int]?
    
    static let dummy1: ECKPlanetaryColonyRoute = .init(contentTypeId: 2268,
                                                       destinationPinId: 1045690545611,
                                                       quantity: 256832,
                                                       routeId: 1399526554,
                                                       sourcePinId: 1045690575739,
                                                       waypoints: [])
    
    static let dummy2: ECKPlanetaryColonyRoute = .init(contentTypeId: 3645,
                                                       destinationPinId: 1045690691229,
                                                       quantity: 20,
                                                       routeId: 1366405933,
                                                       sourcePinId: 1045690691222,
                                                       waypoints: [])
    
    static let dummy3: ECKPlanetaryColonyRoute = .init(contentTypeId: 2268,
                                                       destinationPinId: 1045690691222,
                                                       quantity: 3000,
                                                       routeId: 1366405783,
                                                       sourcePinId: 1045690545611,
                                                       waypoints: [])
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.contentTypeId = try container.decode(Int.self, forKey: .contentTypeId)
        self.destinationPinId = try container.decode(Int.self, forKey: .destinationPinId)
        self.quantity = try container.decode(Float.self, forKey: .quantity)
        self.routeId = try container.decode(Int.self, forKey: .routeId)
        self.sourcePinId = try container.decode(Int.self, forKey: .sourcePinId)
        self.waypoints = try container.decodeIfPresent([Int].self, forKey: .waypoints)
    }
    
    init(contentTypeId: Int,
         destinationPinId: Int,
         quantity: Float,
         routeId: Int,
         sourcePinId: Int,
         waypoints: [Int]?) {
        self.contentTypeId = contentTypeId
        self.destinationPinId = destinationPinId
        self.quantity = quantity
        self.routeId = routeId
        self.sourcePinId = sourcePinId
        self.waypoints = waypoints
    }
    
}

public class ECKPlanetaryColonyPin: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case contents
        case expiryTime = "expiry_time"
        case extractorDetails = "extractor_details"
        case factoryDetails = "factory_details"
        case installTime = "install_time"
        case lastCycleStart = "last_cycle_start"
        case pinId = "pin_id"
        case schematic = "schematic_id"
        case item = "type_id"
    }
    
    public enum PinType: Int {
        case extractor
        case storage
        case factory
    }
    
    public let contents: [ECKPlanetaryColonyPinContent]?
    public let expiryTime: Date?
    public let extractorDetails: ECKPlanetaryColonyPinExtractorDetails?
    public let factoryDetails: ECKPlanetaryColonyPinFactoryDetails?
    public let installTime: Date?
    public let lastCycleStart: Date?
    public let pinId: Int
    public let schematic: ECKPlanetSchematic?
    public let item: ECKItem
    
    private var extractorWarnings: Set<ECKPlanetaryColonyDetails.Warning> {
        var result = Set<ECKPlanetaryColonyDetails.Warning>()
        
        if extractorDetails != nil,
           let expiryTime {
            if expiryTime < Date() {
                result.insert(.extractionExpired)
            } else if expiryTime < Date() + .fromDays(days: 1) {
                result.insert(.extractionExpiresSoon)
            }
        }
        
        return result
    }
    
    private var storageWarnings: Set<ECKPlanetaryColonyDetails.Warning> {
        var result = Set<ECKPlanetaryColonyDetails.Warning>()
        
        // Ignore factories, these are not "real" storages.
        // We only want to have warnings from actual storage units.
        if factoryDetails == nil,
           let capacity = item.capacity,
               capacity > 0 {
            // Fire the warning if there is less than 10% of storage left.
            if contentVolume / capacity >= 0.9 {
                result.insert(.storageRunningFull)
            }
        }
        
        return result
    }
    
    public lazy var warnings: Set<ECKPlanetaryColonyDetails.Warning> = {
        return extractorWarnings.union(storageWarnings)
    }()
    
    public lazy var contentVolume: Float = {
        var result: Float = 0
        
        for content in contents ?? [] {
            result += Float(content.amount) * (content.item.volume ?? 0)
        }
        
        return result
    }()
    
    public lazy var pinType: PinType = {
        if extractorDetails != nil {
            return .extractor
        } else if factoryDetails != nil || schematic != nil {
            return .factory
        } else {
            return .storage
        }
    }()
    
    public static let dummy1: ECKPlanetaryColonyPin = .init(contents: [],
                                                            expiryTime: nil,
                                                            extractorDetails: nil,
                                                            factoryDetails: nil,
                                                            installTime: nil,
                                                            lastCycleStart: .init() - .fromHours(hours: 3.5),
                                                            pinId: 1045690691229,
                                                            schematic: nil,
                                                            item: .init(typeId: 2493))
    
    public static let dummy2: ECKPlanetaryColonyPin = .init(contents: [.init(item: .init(typeId: 2268), amount: 1000000)],
                                                            expiryTime: nil,
                                                            extractorDetails: nil,
                                                            factoryDetails: nil,
                                                            installTime: nil,
                                                            lastCycleStart: .init() - .fromHours(hours: 3.5),
                                                            pinId: 1045690691222,
                                                            schematic: .init(schematicId: 121),
                                                            item: .init(typeId: 2257))
    
    public static let dummy3: ECKPlanetaryColonyPin = .init(contents: [],
                                                            expiryTime: .init() + .fromDays(days: 1),
                                                            extractorDetails: .init(cycleTime: 7200,
                                                                                    headRadius: 0.029988110065460205,
                                                                                    product: .init(typeId: 2268),
                                                                                    quantityPerCycle: 17836),
                                                            factoryDetails: nil,
                                                            installTime: .init() - .fromHours(hours: 3.5),
                                                            lastCycleStart: .init() - .fromHours(hours: 3.5),
                                                            pinId: 1045690575739,
                                                            schematic: nil,
                                                            item: .init(typeId: 3061))
    
    public static let dummy4: ECKPlanetaryColonyPin = .init(contents: [],
                                                            expiryTime: nil,
                                                            extractorDetails: nil,
                                                            factoryDetails: nil,
                                                            installTime: nil,
                                                            lastCycleStart: nil,
                                                            pinId: 1045690545611,
                                                            schematic: nil,
                                                            item: .init(typeId: 2533))
    
    // https://developers.eveonline.com/docs/guides/pi/#extraction-calculation
    public lazy var extractorValues: [(date: Date, units: Int)] = {
        guard let extractorDetails,
              let installTime,
              let expiryTime,
              let cycleTime = extractorDetails.cycleTime,
              let quantityPerCycle = extractorDetails.quantityPerCycle else {
            return []
        }
              
        let duration: TimeInterval = expiryTime.timeIntervalSince(installTime)
        let numberOfIterations: Int = Int(duration / Double(cycleTime))
        let barWidth: Double = Double(cycleTime) / 900
        
        guard let decayFactorFloat = ECKSDEManager.shared.getAttributeValue(attributeId: 1683, typeId: item.typeId) else {
            logger.error("Cannot get Decay Factor")
            return []
        }
        
        guard let noiseFactorFloat = ECKSDEManager.shared.getAttributeValue(attributeId: 1687, typeId: item.typeId) else {
            logger.error("Cannot get Noise Factor")
            return []
        }
        
        let decayFactor: Double = Double(decayFactorFloat)
        let noiseFactor: Double = Double(noiseFactorFloat)
        
        var values: [(date: Date, units: Int)] = []
        for i in 0..<numberOfIterations {
            let t: Double = (Double(i) + 0.5) * barWidth
            let decayValue: Double = Double(quantityPerCycle) / (1 + t * decayFactor)
            let phaseShift: Double = pow(Double(quantityPerCycle), 0.7)
            
            let sinA: Double = cos(phaseShift + t * (1.0 / 12.0))
            let sinB: Double = cos(phaseShift / 2 + t * 0.2)
            let sinC: Double = cos(t * 0.5)
            let sinStuff: Double = max((sinA + sinB + sinC) / 3, 0)
            
            let barHeight: Double = decayValue * (1 + noiseFactor * sinStuff)
            values.append((date: installTime.addingTimeInterval(TimeInterval(cycleTime * i)), units: Int(barWidth * barHeight)))
        }
        
        return values
    }()
    
    public var extractorStartTime: Date? {
        return extractorValues.first?.date
    }
    
    public var extractorEndTime: Date? {
        return extractorValues.last?.date
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.contents = try container.decodeIfPresent([ECKPlanetaryColonyPinContent].self, forKey: .contents)
        self.expiryTime = try container.decodeIfPresent(Date.self, forKey: .expiryTime)
        self.extractorDetails = try container.decodeIfPresent(ECKPlanetaryColonyPinExtractorDetails.self, forKey: .extractorDetails)
        self.factoryDetails = try container.decodeIfPresent(ECKPlanetaryColonyPinFactoryDetails.self, forKey: .factoryDetails)
        self.installTime = try container.decodeIfPresent(Date.self, forKey: .installTime)
        self.lastCycleStart = try container.decodeIfPresent(Date.self, forKey: .lastCycleStart)
        self.pinId = try container.decode(Int.self, forKey: .pinId)
        self.schematic = try container.decodeIfPresent(ECKPlanetSchematic.self, forKey: .schematic)
        self.item = try container.decode(ECKItem.self, forKey: .item)
    }
    
    init(contents: [ECKPlanetaryColonyPinContent]?,
         expiryTime: Date?,
         extractorDetails: ECKPlanetaryColonyPinExtractorDetails?,
         factoryDetails: ECKPlanetaryColonyPinFactoryDetails?,
         installTime: Date?,
         lastCycleStart: Date?,
         pinId: Int,
         schematic: ECKPlanetSchematic?,
         item: ECKItem) {
        self.contents = contents
        self.expiryTime = expiryTime
        self.extractorDetails = extractorDetails
        self.factoryDetails = factoryDetails
        self.installTime = installTime
        self.lastCycleStart = lastCycleStart
        self.pinId = pinId
        self.schematic = schematic
        self.item = item
    }
    
}

public struct ECKPlanetaryColonyPinContent: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case item = "type_id"
        case amount
    }
    
    public let item: ECKItem
    public let amount: Int
    
    public var volume: Float {
        return (item.volume ?? 0) * Float(amount)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.item = try container.decode(ECKItem.self, forKey: .item)
        self.amount = try container.decode(Int.self, forKey: .amount)
    }
    
    init(item: ECKItem,
         amount: Int) {
        self.item = item
        self.amount = amount
    }
    
}

public class ECKPlanetaryColonyPinExtractorDetails: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case cycleTime = "cycle_time"
        case headRadius = "head_radius"
        case product = "product_type_id"
        case quantityPerCycle = "qty_per_cycle"
    }
    
    public let cycleTime: Int?
    public let headRadius: Float?
    public let product: ECKItem?
    public let quantityPerCycle: Int?
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cycleTime = try container.decodeIfPresent(Int.self, forKey: .cycleTime)
        self.headRadius = try container.decodeIfPresent(Float.self, forKey: .headRadius)
        self.product = try container.decodeIfPresent(ECKItem.self, forKey: .product)
        self.quantityPerCycle = try container.decodeIfPresent(Int.self, forKey: .quantityPerCycle)
    }
    
    init(cycleTime: Int?,
         headRadius: Float?,
         product: ECKItem?,
         quantityPerCycle: Int?) {
        self.cycleTime = cycleTime
        self.headRadius = headRadius
        self.product = product
        self.quantityPerCycle = quantityPerCycle
    }
    
}

public class ECKPlanetaryColonyPinFactoryDetails: Decodable {

    enum CodingKeys: String, CodingKey {
        case schematic = "schematic_id"
    }
    
    let schematic: ECKPlanetSchematic
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.schematic = try container.decode(ECKPlanetSchematic.self, forKey: .schematic)
    }
    
    init(schematic: ECKPlanetSchematic) {
        self.schematic = schematic
    }
    
}
