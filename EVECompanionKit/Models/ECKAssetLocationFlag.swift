//
//  ECKAssetLocationFlag.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 24.06.24.
//

import Foundation

public enum ECKAssetLocationFlag: String, Decodable, Sendable {
    
    case unknown
    
    case AssetSafety
    case AutoFit
    case BoosterBay
    case Cargo
    case CorporationGoalDeliveries
    case CorpseBay
    case Deliveries
    case DroneBay
    case FighterBay
    case FighterTube0
    case FighterTube1
    case FighterTube2
    case FighterTube3
    case FighterTube4
    case FleetHangar
    case FrigateEscapeBay
    case Hangar
    case HangarAll
    case HiSlot0
    case HiSlot1
    case HiSlot2
    case HiSlot3
    case HiSlot4
    case HiSlot5
    case HiSlot6
    case HiSlot7
    case HiddenModifiers
    case Implant
    case LoSlot0
    case LoSlot1
    case LoSlot2
    case LoSlot3
    case LoSlot4
    case LoSlot5
    case LoSlot6
    case LoSlot7
    case Locked
    case MedSlot0
    case MedSlot1
    case MedSlot2
    case MedSlot3
    case MedSlot4
    case MedSlot5
    case MedSlot6
    case MedSlot7
    case MobileDepotHold
    case QuafeBay
    case RigSlot0
    case RigSlot1
    case RigSlot2
    case RigSlot3
    case RigSlot4
    case RigSlot5
    case RigSlot6
    case RigSlot7
    case ShipHangar
    case Skill
    case SpecializedAmmoHold
    case SpecializedAsteroidHold
    case SpecializedCommandCenterHold
    case SpecializedFuelBay
    case SpecializedGasHold
    case SpecializedIceHold
    case SpecializedIndustrialShipHold
    case SpecializedLargeShipHold
    case SpecializedMaterialBay
    case SpecializedMediumShipHold
    case SpecializedMineralHold
    case SpecializedOreHold
    case SpecializedPlanetaryCommoditiesHold
    case SpecializedSalvageHold
    case SpecializedShipHold
    case SpecializedSmallShipHold
    case StructureDeedBay
    case SubSystemBay
    case SubSystemSlot0
    case SubSystemSlot1
    case SubSystemSlot2
    case SubSystemSlot3
    case SubSystemSlot4
    case SubSystemSlot5
    case SubSystemSlot6
    case SubSystemSlot7
    case Unlocked
    case Wardrobe
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        
        guard let value = ECKAssetLocationFlag(rawValue: stringValue) else {
            logger.warning("Unknown asset location flag \(stringValue)")
            self = .unknown
            return
        }
        
        self = value
    }
    
}
