//
//  ECKCharacterFitting.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import Foundation

public class ECKCharacterFitting: Codable, Identifiable, Hashable, ObservableObject {
    
    private enum CodingKeys: CodingKey {
        case description
        case fittingId
        case esiFittingId
        case name
        case ship
        case target
        case structure
        case highSlotModules
        case midSlotModules
        case lowSlotModules
        case rigs
        case subsystems
        case drones
        case skills
    }
    
    public typealias AttributeID = Int
    
    static let attributeMassId: Int = 4
    static let attributeStructureHPId: Int = 9
    static let attributePowerOutput: Int = 11
    static let attributeLowSlotsId: Int = 12
    static let attributeMidSlotsId: Int = 13
    static let attributeHighSlotsId: Int = 14
    static let attributePowerLoadId: Int = 15
    static let attributePowerGridUsageId: Int = 30
    static let attributeMaxVelocityyId: Int = 37
    static let attributeCapacityId: Int = 38
    static let attributeCpuOutputId: Int = 48
    static let attributeCpuLoadId: Int = 49
    static let attributeCpuUsageId: Int = 50
    static let attributeRoFId: Int = 51
    static let attributeDamageMultiplierId: Int = 64
    static let attributeInertiaModifierId: Int = 70
    static let attributeActivationTimeId: Int = 73
    static let attributeMaximumTargetingRange: Int = 76
    static let attributeLauncherHardpointsId: Int = 101
    static let attributeTurrentHardpointsId: Int = 102
    static let attributeStructureKineticResistId: Int = 109
    static let attributeStructureThermalResistId: Int = 110
    static let attributeStructureExplosiveResistId: Int = 111
    static let attributeStructureEMResistId: Int = 113
    static let attributeEMDamageId: Int = 114
    static let attributeExplosiveDamageId: Int = 116
    static let attributeKineticDamageId: Int = 117
    static let attributeThermalDamageId: Int = 118
    static let attributeChargeSizeId: Int = 128
    static let attributeMaximumLockedTargetsId: Int = 192
    static let attributeRadarSensorStrengthId: Int = 208
    static let attributeLadarSensorStrengthId: Int = 209
    static let attributeMagnetometricSensorStrengthId: Int = 210
    static let attributeGravimetricSensorStrengthId: Int = 211
    static let attributeMissileDamageMultiplierId: Int = 212
    static let attributeShieldHPId: Int = 263
    static let attributeArmorHPId: Int = 265
    static let attributeArmorKineticResistId: Int = 269
    static let attributeArmorThermalResistId: Int = 270
    static let attributeArmorExplosiveResistId: Int = 268
    static let attributeArmorEMResistId: Int = 267
    static let attributeShieldEMResistId: Int = 271
    static let attributeShieldExplosiveResistId: Int = 272
    static let attributeShieldKineticResistId: Int = 273
    static let attributeShieldThermalResistId: Int = 274
    static let attributeDroneCapacityId: Int = 283
    static let attributeVolumeId: Int = 161
    static let attributeRadiusId: Int = 162
    static let attributeSkillLevelId: Int = 280
    static let attributeSignatureRadiusId: Int = 552
    static let attributeScanResolutionId: Int = 564
    static let attributeWarpSpeedMultiplierId: Int = 600
    static let attributeRigSlotsId: Int = 1137
    static let attributeRigSlotsId2: Int = 1154
    static let attributeDroneBandwidthId: Int = 1271
    static let attributeDroneBandwidthNeededId: Int = 1272
    static let attributeWarpSpeedId: Int = 1281
    static let attributeSubsystemSlotsId: Int = 1367
    static let attributeTurretModificatorId: Int = 1368
    static let attributeLauncherModificatorId: Int = 1369
    static let attributeReloadTimeId: Int = 1795
    static let attributeActivationTimeHighIsGoodId: Int = 3115
    
    public var id: UUID {
        return fittingId
    }
    
    public let description: String
    public let fittingId: UUID
    public let esiFittingId: Int?
    public var items: [ECKCharacterFittingItem] {
        return highSlotModules
        + midSlotModules
        + lowSlotModules
        + rigs
        + subsystems
        + drones
    }
    @Published public var name: String
    public let ship: ECKCharacterFittingItem
    public let target: ECKCharacterFittingItem = .init(flag: .ShipHangar,
                                                       quantity: 1,
                                                       item: .init(typeId: 0))
    public let structure: ECKCharacterFittingItem = .init(flag: .ShipHangar,
                                                          quantity: 1,
                                                          item: .init(typeId: 0))
    
    public var highSlotModules: [ECKCharacterFittingItem]
    public var midSlotModules: [ECKCharacterFittingItem]
    public var lowSlotModules: [ECKCharacterFittingItem]
    public var rigs: [ECKCharacterFittingItem]
    public var subsystems: [ECKCharacterFittingItem]
    public var drones: [ECKCharacterFittingItem]
    
    public var launcherHardPoints: Int {
        return Int(ship.attributes[Self.attributeLauncherHardpointsId]?.value ?? 0)
    }
    
    public var usedLauncherHardPoints: Int {
        return highSlotModules.reduce(0) { partialResult, item in
            if item.usesLauncherSlot {
                return partialResult + 1
            } else {
                return partialResult
            }
        }
    }
    
    public var turretHardPoints: Int {
        return Int(ship.attributes[Self.attributeTurrentHardpointsId]?.value ?? 0)
    }
    
    public var usedTurretHardPoints: Int {
        return highSlotModules.reduce(0) { partialResult, item in
            if item.usesTurretSlot {
                return partialResult + 1
            } else {
                return partialResult
            }
        }
    }
    
    public var lowSlots: Int {
        return Int(ship.attributes[Self.attributeLowSlotsId]?.value ?? 0)
    }
    
    public var midSlots: Int {
        return Int(ship.attributes[Self.attributeMidSlotsId]?.value ?? 0)
    }
    
    public var highSlots: Int {
        return Int(ship.attributes[Self.attributeHighSlotsId]?.value ?? 0)
    }
    
    public var rigSlots: Int {
        return Int(ship.attributes[Self.attributeRigSlotsId]?.value ?? ship.attributes[Self.attributeRigSlotsId2]?.value ?? 0)
    }
    
    public var subsystemSlots: Int {
        return Int(ship.attributes[Self.attributeSubsystemSlotsId]?.value ?? 0)
    }
    
    public var maxCPU: Float? {
        return ship.attributes[Self.attributeCpuOutputId]?.value
    }
    
    public var cpuLoad: Float? {
        return ship.attributes[Self.attributeCpuLoadId]?.value
    }
    
    public var powerOutput: Float? {
        return ship.attributes[Self.attributePowerOutput]?.value
    }
    
    public var powerLoad: Float? {
        return ship.attributes[Self.attributePowerLoadId]?.value
    }
    
    public var mass: Float? {
        return ship.attributes[Self.attributeMassId]?.value
    }
    
    public var inertiaModifier: Float? {
        return ship.attributes[Self.attributeInertiaModifierId]?.value
    }
    
    public var cargo: Float? {
        return ship.attributes[Self.attributeCapacityId]?.value
    }
    
    public var maxDroneCapacity: Float? {
        return ship.attributes[Self.attributeDroneCapacityId]?.value
    }
    
    public var maxVelocity: Float? {
        return ship.attributes[Self.attributeMaxVelocityyId]?.value
    }
    
    public var usedDroneCapacity: Float? {
        var result: Float = 0
        
        for drone in drones {
            let volume = drone.attributes[Self.attributeVolumeId]?.value ??
                         drone.attributes[Self.attributeVolumeId]?.baseValue ?? 0
            result += volume * Float(drone.quantity)
        }
        
        return result
    }
    
    public var maxDroneBandwidth: Float? {
        return ship.attributes[Self.attributeDroneBandwidthId]?.value
    }
    
    public var usedDroneBandwidth: Float? {
        var result: Float = 0
        
        for drone in drones {
            let volume = drone.attributes[Self.attributeDroneBandwidthNeededId]?.value ??
                         drone.attributes[Self.attributeDroneBandwidthNeededId]?.baseValue ?? 0
            result += volume * Float(drone.quantity)
        }
        
        return result
    }
    
    public var alignTime: Float? {
        guard let mass,
              let inertiaModifier else {
            return nil
        }
        
        return (log(2) * inertiaModifier * mass) / 500000
    }
    
    public var maximumLockedTargets: Float? {
        return ship.attributes[Self.attributeMaximumLockedTargetsId]?.value
    }
    
    public var scanResolution: Float? {
        return ship.attributes[Self.attributeScanResolutionId]?.value
    }
    
    public var sensorStrength: Float? {
        guard ship.attributes.isEmpty == false else {
            return nil
        }
        
        let radar = ship.attributes[Self.attributeRadarSensorStrengthId]?.value ?? 0
        let ladar = ship.attributes[Self.attributeLadarSensorStrengthId]?.value ?? 0
        let magnetometric = ship.attributes[Self.attributeMagnetometricSensorStrengthId]?.value ?? 0
        let gravimetric = ship.attributes[Self.attributeGravimetricSensorStrengthId]?.value ?? 0
        
        return max(radar, ladar, magnetometric, gravimetric)
    }
    
    public var maximumTargetingRange: Float? {
        return ship.attributes[Self.attributeMaximumTargetingRange]?.value
    }
    
    public var signatureRadius: Float? {
        return ship.attributes[Self.attributeSignatureRadiusId]?.value
    }
    
    public var warpSpeed: Float? {
        guard let speed = ship.attributes[Self.attributeWarpSpeedId]?.value,
              let multiplier = ship.attributes[Self.attributeWarpSpeedMultiplierId]?.value else {
            return nil
        }
        
        return speed * multiplier
    }
    
    public var canUseDrones: Bool {
        return maxDroneCapacity ?? 0 > 0
    }
    
    public static let dummyAvatar: ECKCharacterFitting = {
        let turret: ECKCharacterFittingItem = .init(flag: .HiSlot0, quantity: 1, item: .init(typeId: 37299))
        turret.charge = .init(flag: .HiSlot0, quantity: 1, item: .init(typeId: 41336))
        
        let fitting = ECKCharacterFitting(fittingId: UUID(),
                                          description: "Just my avatar",
                                          esiFittingId: nil,
                                          items: [
                                            turret
                                          ],
                                          name: "EVECompanion's Avatar",
                                          ship: .init(typeId: 11567))
        fitting.calculateAttributes(skills: .dummy)
        return fitting
    }()
    
    public static let dummyVNI: ECKCharacterFitting = {
        let drones: ECKCharacterFittingItem = .init(flag: .DroneBay, quantity: 5, item: .init(typeId: 2488))
        
        let fitting = ECKCharacterFitting(fittingId: UUID(),
                                          description: "VNI",
                                          esiFittingId: nil,
                                          items: [
                                            drones
                                          ],
                                          name: "EVECompanion's VNI",
                                          ship: .init(typeId: 17843))
        fitting.calculateAttributes(skills: .dummy)
        return fitting
    }()
    
    public var resistances: Resistances? {
        let attributes = ship.attributes
        
        guard attributes.isEmpty == false else {
            return nil
        }
        
        let structure: ResistanceStats = .init(hp: attributes[Self.attributeStructureHPId]?.value ?? 0,
                                               em: attributes[Self.attributeStructureEMResistId]?.value ?? 0,
                                               explosive: attributes[Self.attributeStructureExplosiveResistId]?.value ?? 0,
                                               kinetic: attributes[Self.attributeStructureKineticResistId]?.value ?? 0,
                                               thermal: attributes[Self.attributeStructureThermalResistId]?.value ?? 0)
        
        let armor: ResistanceStats = .init(hp: attributes[Self.attributeArmorHPId]?.value ?? 0,
                                           em: attributes[Self.attributeArmorEMResistId]?.value ?? 0,
                                           explosive: attributes[Self.attributeArmorExplosiveResistId]?.value ?? 0,
                                           kinetic: attributes[Self.attributeArmorKineticResistId]?.value ?? 0,
                                           thermal: attributes[Self.attributeArmorThermalResistId]?.value ?? 0)
        
        let shield: ResistanceStats = .init(hp: attributes[Self.attributeShieldHPId]?.value ?? 0,
                                            em: attributes[Self.attributeShieldEMResistId]?.value ?? 0,
                                            explosive: attributes[Self.attributeShieldExplosiveResistId]?.value ?? 0,
                                            kinetic: attributes[Self.attributeShieldKineticResistId]?.value ?? 0,
                                            thermal: attributes[Self.attributeShieldThermalResistId]?.value ?? 0)
        
        return .init(structure: structure, armor: armor, shield: shield)
    }
    
    public var fittingAttributes: [(attribute: ECKSDEManager.ItemAttribute, fittingAttribute: FittingAttribute)] {
        var fittingAttributes: [FittingAttribute] = Array(ship.attributes.values)
        fittingAttributes.sort(by: { $0.id < $1.id })
        let result: [(attribute: ECKSDEManager.ItemAttribute, fittingAttribute: FittingAttribute)] = fittingAttributes.map { fittingAttribute in
            let attribute = ECKSDEManager.shared.itemAttribute(fittingAttribute.id)
            return (attribute: attribute, fittingAttribute: fittingAttribute)
        }.compactMap { attributes in
            guard let attribute = attributes.attribute else {
                return nil
            }
            
            return (attribute: attribute, fittingAttribute: attributes.fittingAttribute)
        }
        
        return result
    }
    
    public var damageProfile: DamageProfile {
        let itemDamages = items.compactMap({ $0.damageProfile })
        
        return itemDamages.reduce(.zero) { partialResult, profile in
            return partialResult + profile
        }
    }
    
    internal var skills: [ECKCharacterFittingItem] = []
    internal var lastUsedSkills: ECKCharacterSkills?
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.description = try container.decode(String.self, forKey: .description)
        self.fittingId = try container.decode(UUID.self, forKey: .fittingId)
        self.esiFittingId = try container.decodeIfPresent(Int.self, forKey: .esiFittingId)
        self.name = try container.decode(String.self, forKey: .name)
        self.ship = try container.decode(ECKCharacterFittingItem.self, forKey: .ship)
        self.highSlotModules = try container.decode([ECKCharacterFittingItem].self, forKey: .highSlotModules)
        self.midSlotModules = try container.decode([ECKCharacterFittingItem].self, forKey: .midSlotModules)
        self.lowSlotModules = try container.decode([ECKCharacterFittingItem].self, forKey: .lowSlotModules)
        self.rigs = try container.decode([ECKCharacterFittingItem].self, forKey: .rigs)
        self.subsystems = try container.decode([ECKCharacterFittingItem].self, forKey: .subsystems)
        self.drones = try container.decode([ECKCharacterFittingItem].self, forKey: .drones)
        self.skills = try container.decode([ECKCharacterFittingItem].self, forKey: .skills)
    }
    
    internal convenience init(fitting: ESIFitting) {
        self.init(fittingId: UUID(),
                  description: fitting.description,
                  esiFittingId: fitting.fittingId,
                  items: fitting.items,
                  name: fitting.name,
                  ship: fitting.ship)
    }
    
    internal convenience init(ship: ECKItem) {
        self.init(fittingId: UUID(),
                  description: "",
                  esiFittingId: nil,
                  items: [],
                  name: ship.name,
                  ship: ship)
    }
    
    internal init(fittingId: UUID,
                  description: String,
                  esiFittingId: Int?,
                  items: [ECKCharacterFittingItem],
                  name: String,
                  ship: ECKItem) {
        self.description = description
        self.fittingId = fittingId
        self.esiFittingId = esiFittingId
        
        var highSlotItems: [ECKCharacterFittingItem] = []
        var midSlotItems: [ECKCharacterFittingItem] = []
        var lowSlotItems: [ECKCharacterFittingItem] = []
        var rigs: [ECKCharacterFittingItem] = []
        var subsystems: [ECKCharacterFittingItem] = []
        var drones: [ECKCharacterFittingItem] = []
        for item in items.sorted(by: { $0.flag.rawValue < $1.flag.rawValue }) {
            switch item.flag {
            case .unknown:
                continue
            case .AssetSafety:
                continue
            case .AutoFit:
                continue
            case .BoosterBay:
                continue
            case .Cargo:
                continue
            case .CorporationGoalDeliveries:
                continue
            case .CorpseBay:
                continue
            case .Deliveries:
                continue
            case .DroneBay:
                drones.append(item)
            case .FighterBay:
                // TODO
                continue
            case .FighterTube0:
                // TODO
                continue
            case .FighterTube1:
                // TODO
                continue
            case .FighterTube2:
                // TODO
                continue
            case .FighterTube3:
                // TODO
                continue
            case .FighterTube4:
                // TODO
                continue
            case .FleetHangar:
                continue
            case .FrigateEscapeBay:
                continue
            case .Hangar:
                continue
            case .HangarAll:
                continue
            case .HiSlot0:
                highSlotItems.append(item)
            case .HiSlot1:
                highSlotItems.append(item)
            case .HiSlot2:
                highSlotItems.append(item)
            case .HiSlot3:
                highSlotItems.append(item)
            case .HiSlot4:
                highSlotItems.append(item)
            case .HiSlot5:
                highSlotItems.append(item)
            case .HiSlot6:
                highSlotItems.append(item)
            case .HiSlot7:
                highSlotItems.append(item)
            case .HiddenModifiers:
                continue
            case .Implant:
                // TODO
                continue
            case .LoSlot0:
                lowSlotItems.append(item)
            case .LoSlot1:
                lowSlotItems.append(item)
            case .LoSlot2:
                lowSlotItems.append(item)
            case .LoSlot3:
                lowSlotItems.append(item)
            case .LoSlot4:
                lowSlotItems.append(item)
            case .LoSlot5:
                lowSlotItems.append(item)
            case .LoSlot6:
                lowSlotItems.append(item)
            case .LoSlot7:
                lowSlotItems.append(item)
            case .Locked:
                continue
            case .MedSlot0:
                midSlotItems.append(item)
            case .MedSlot1:
                midSlotItems.append(item)
            case .MedSlot2:
                midSlotItems.append(item)
            case .MedSlot3:
                midSlotItems.append(item)
            case .MedSlot4:
                midSlotItems.append(item)
            case .MedSlot5:
                midSlotItems.append(item)
            case .MedSlot6:
                midSlotItems.append(item)
            case .MedSlot7:
                midSlotItems.append(item)
            case .MobileDepotHold:
                continue
            case .QuafeBay:
                continue
            case .RigSlot0:
                rigs.append(item)
            case .RigSlot1:
                rigs.append(item)
            case .RigSlot2:
                rigs.append(item)
            case .RigSlot3:
                rigs.append(item)
            case .RigSlot4:
                rigs.append(item)
            case .RigSlot5:
                rigs.append(item)
            case .RigSlot6:
                rigs.append(item)
            case .RigSlot7:
                rigs.append(item)
            case .ShipHangar:
                continue
            case .Skill:
                continue
            case .SpecializedAmmoHold:
                continue
            case .SpecializedAsteroidHold:
                continue
            case .SpecializedCommandCenterHold:
                continue
            case .SpecializedFuelBay:
                continue
            case .SpecializedGasHold:
                continue
            case .SpecializedIceHold:
                continue
            case .SpecializedIndustrialShipHold:
                continue
            case .SpecializedLargeShipHold:
                continue
            case .SpecializedMaterialBay:
                continue
            case .SpecializedMediumShipHold:
                continue
            case .SpecializedMineralHold:
                continue
            case .SpecializedOreHold:
                continue
            case .SpecializedPlanetaryCommoditiesHold:
                continue
            case .SpecializedSalvageHold:
                continue
            case .SpecializedShipHold:
                continue
            case .SpecializedSmallShipHold:
                continue
            case .StructureDeedBay:
                continue
            case .SubSystemBay:
                continue
            case .SubSystemSlot0:
                subsystems.append(item)
            case .SubSystemSlot1:
                subsystems.append(item)
            case .SubSystemSlot2:
                subsystems.append(item)
            case .SubSystemSlot3:
                subsystems.append(item)
            case .SubSystemSlot4:
                subsystems.append(item)
            case .SubSystemSlot5:
                subsystems.append(item)
            case .SubSystemSlot6:
                subsystems.append(item)
            case .SubSystemSlot7:
                subsystems.append(item)
            case .Unlocked:
                continue
            case .Wardrobe:
                continue
            }
        }
        self.highSlotModules = highSlotItems
        self.midSlotModules = midSlotItems
        self.lowSlotModules = lowSlotItems
        self.rigs = rigs
        self.subsystems = subsystems
        self.drones = drones
        self.name = name
        self.ship = .init(flag: .ShipHangar,
                          quantity: 1,
                          item: ship)
    }
    
    public static func == (lhs: ECKCharacterFitting, rhs: ECKCharacterFitting) -> Bool {
        return lhs.description == rhs.description
        && lhs.fittingId == rhs.fittingId
        && lhs.items == rhs.items
        && lhs.name == rhs.name
        && lhs.ship == rhs.ship
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
        hasher.combine(fittingId)
        hasher.combine(items)
        hasher.combine(name)
        hasher.combine(ship)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.description, forKey: .description)
        try container.encode(self.fittingId, forKey: .fittingId)
        try container.encodeIfPresent(self.esiFittingId, forKey: .esiFittingId)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.ship, forKey: .ship)
        try container.encode(self.target, forKey: .target)
        try container.encode(self.structure, forKey: .structure)
        try container.encode(self.highSlotModules, forKey: .highSlotModules)
        try container.encode(self.midSlotModules, forKey: .midSlotModules)
        try container.encode(self.lowSlotModules, forKey: .lowSlotModules)
        try container.encode(self.rigs, forKey: .rigs)
        try container.encode(self.subsystems, forKey: .subsystems)
        try container.encode(self.drones, forKey: .drones)
        try container.encode(self.skills, forKey: .skills)
    }
    
    public func addModule(item: ECKItem,
                          skills: ECKCharacterSkills,
                          moduleToReplace: ECKCharacterFittingItem?,
                          manager: ECKFittingManager) throws(ECKAddModuleError) {
        guard let slotType = item.slotType else {
            throw .moduleNotFittable(item)
        }
        
        try checkItemIsFittable(item: item)
        
        if let moduleToReplace {
            let originalFlag = moduleToReplace.flag
            let newModule = ECKCharacterFittingItem(flag: originalFlag,
                                                    quantity: 1,
                                                    item: item)
            
            guard moduleToReplace.item.slotType == newModule.item.slotType else {
                throw .generic
            }
            
            switch slotType {
            case .rig:
                rigs = replaceModule(oldModule: moduleToReplace, newModule: newModule, in: rigs)
            case .subsystem:
                subsystems = replaceModule(oldModule: moduleToReplace, newModule: newModule, in: subsystems)
            case .high:
                highSlotModules = replaceModule(oldModule: moduleToReplace, newModule: newModule, in: highSlotModules)
            case .mid:
                midSlotModules = replaceModule(oldModule: moduleToReplace, newModule: newModule, in: midSlotModules)
            case .low:
                lowSlotModules = replaceModule(oldModule: moduleToReplace, newModule: newModule, in: lowSlotModules)
            }
        } else {
            switch slotType {
            case .rig:
                guard self.rigs.count < self.rigSlots else {
                    throw .noFreeSlot(item, .rig)
                }
                
                self.rigs.append(.init(flag: .init(rawValue: "RigSlot\(rigs.count)")!, quantity: 1, item: item))
            case .subsystem:
                guard self.subsystems.count < self.subsystemSlots else {
                    throw .noFreeSlot(item, .subsystem)
                }
                
                self.subsystems.append(.init(flag: .init(rawValue: "SubSystemSlot\(subsystems.count)")!, quantity: 1, item: item))
            case .high:
                guard self.highSlotModules.count < self.highSlots else {
                    throw .noFreeSlot(item, .high)
                }
                
                self.highSlotModules.append(.init(flag: .init(rawValue: "HiSlot\(highSlotModules.count)")!, quantity: 1, item: item))
            case .mid:
                guard self.midSlotModules.count < self.midSlots else {
                    throw .noFreeSlot(item, .mid)
                }
                
                self.midSlotModules.append(.init(flag: .init(rawValue: "MedSlot\(midSlotModules.count)")!, quantity: 1, item: item))
            case .low:
                guard self.lowSlotModules.count < self.lowSlots else {
                    throw .noFreeSlot(item, .low)
                }
                
                self.lowSlotModules.append(.init(flag: .init(rawValue: "LoSlot\(lowSlotModules.count)")!, quantity: 1, item: item))
            }
        }
        
        fixModuleFlags()
        calculateAttributes(skills: nil)
        manager.saveFitting(self)
    }
    
    private func replaceModule(oldModule: ECKCharacterFittingItem,
                               newModule: ECKCharacterFittingItem,
                               in modules: [ECKCharacterFittingItem]) -> [ECKCharacterFittingItem] {
        var newArray: [ECKCharacterFittingItem] = []
        
        for module in modules {
            if module.id == oldModule.id {
                newArray.append(newModule)
            } else {
                newArray.append(module)
            }
        }
        
        return newArray
    }
    
    private func fixModuleFlags() {
        fixModuleFlags(in: rigs, prefix: "RigSlot")
        fixModuleFlags(in: subsystems, prefix: "SubSystemSlot")
        fixModuleFlags(in: highSlotModules, prefix: "HiSlot")
        fixModuleFlags(in: midSlotModules, prefix: "MedSlot")
        fixModuleFlags(in: lowSlotModules, prefix: "LoSlot")
    }
    
    private func fixModuleFlags(in modules: [ECKCharacterFittingItem], prefix: String) {
        for (index, module) in modules.enumerated() {
            module.flag = .init(rawValue: "\(prefix)\(index)")!
        }
    }
    
    public func addCharge(_ charge: ECKItem, into module: ECKCharacterFittingItem, batchInsert: Bool) {
        if batchInsert {
            let moduleTypeId: Int = module.item.typeId
            
            for item in items where item.item.typeId == moduleTypeId {
                item.charge = .init(flag: module.flag,
                                    quantity: 1,
                                    item: charge)
            }
        } else {
            module.charge = .init(flag: module.flag,
                                  quantity: 1,
                                  item: charge)
        }
        
        calculateAttributes(skills: nil)
    }
    
    public func canBatchInsert(charge: ECKItem, into module: ECKCharacterFittingItem) -> Bool {
        let moduleTypeId: Int = module.item.typeId
        return self.items.filter({ $0.item.typeId == moduleTypeId }).count > 1
    }
    
    public func removeCharge(from item: ECKCharacterFittingItem, manager: ECKFittingManager) {
        item.charge = nil
        calculateAttributes(skills: nil)
        manager.saveFitting(self)
    }
    
    public func removeModule(item: ECKCharacterFittingItem, manager: ECKFittingManager) {
        switch item.item.slotType {
        case .high:
            highSlotModules = highSlotModules.filter { $0.id != item.id }
        case .mid:
            midSlotModules = midSlotModules.filter { $0.id != item.id }
        case .low:
            lowSlotModules = lowSlotModules.filter { $0.id != item.id }
        case .subsystem:
            subsystems = subsystems.filter({ $0.id != item.id })
        case .rig:
            rigs = rigs.filter { $0.id != item.id }
            
        case .none:
            return
        }
        
        calculateAttributes(skills: nil)
        manager.saveFitting(self)
    }
    
    public func setName(_ name: String, manager: ECKFittingManager) {
        self.name = name
        manager.saveFitting(self)
    }
    
}
