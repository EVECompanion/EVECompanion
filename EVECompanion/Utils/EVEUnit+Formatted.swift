//
//  EVEUnit+Formatted.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 05.04.25.
//

import Foundation
import EVECompanionKit

extension EVEUnit {
    
    func formatted(_ value: Float) -> String {
        switch self {
        case .length:
            return ECFormatters.attributeValue(value / 1000) + " km"
        case .mass:
            return ECFormatters.attributeValue(value) + " kg"
        case .time:
            return ECFormatters.timeInterval(timeInterval: TimeInterval(value))
        case .electricCurrent:
            return value.description
        case .temperature:
            return value.description
        case .amountOfSubstance:
            return value.description
        case .luminousIntensity:
            return value.description
        case .area:
            return value.description
        case .volume:
            return ECFormatters.attributeValue(value) + " m³"
        case .speed:
            return ECFormatters.attributeValue(value) + " m/s"
        case .acceleration:
            return ECFormatters.attributeValue(value) + " m/s"
        case .waveNumber:
            return value.description
        case .massDensity:
            return value.description
        case .specificVolume:
            return value.description
        case .currentDensity:
            return value.description
        case .magneticFieldStrength:
            return value.description
        case .amountOfSubstanceConcentration:
            return value.description
        case .luminance:
            return value.description
        case .massFraction:
            return value.description
        case .milliseconds:
            return ECFormatters.timeInterval(timeInterval: TimeInterval(value / 1000))
        case .millimeters:
            return ECFormatters.attributeValue(value) + " mm"
        case .megaPascals:
            return value.description
        case .multiplier:
            return ECFormatters.attributeValue(value) + "x"
        case .percentage:
            return ECFormatters.attributeValue(value) + "%"
        case .teraflops:
            return ECFormatters.attributeValue(value) + " tf"
        case .megawatts:
            return ECFormatters.attributeValue(value) + " MW"
        case .inverseAbsolutePercent:
            return ECFormatters.attributeValue(100 - (value * 100)) + "%"
        case .modifierPercent:
            let result = ECFormatters.attributeValue(100 - (value * 100)) + "%"
            if value >= 1 {
                return result
            } else {
                return "-" + result
            }
        case .inversedModifierPercent:
            let result = ECFormatters.attributeValue(((1 - value) * 100)) + "%"
            if value <= 1 {
                return result
            } else {
                return "-" + result
            }
        case .radiansPerSecond:
            return value.description
        case .hitpoints:
            return ECFormatters.attributeValue(value) + " HP"
        case .capacitorUnits:
            return ECFormatters.attributeValue(value) + " GJ"
        case .groupId:
            return ECFormatters.attributeValue(value)
        case .typeId:
            return ECFormatters.attributeValue(value)
        case .sizeClass:
            switch value {
            case 1:
                return "Small"
            case 2:
                return "Medium"
            case 3:
                return "Large"
            case 4:
                return "X-Large"
            default:
                return ECFormatters.attributeValue(value)
            }
        case .oreUnits:
            return ECFormatters.attributeValue(value)
        case .attributeId:
            return ECFormatters.attributeValue(value)
        case .attributePoints:
            return ECFormatters.attributeValue(value) + " points"
        case .realPercent:
            return ECFormatters.attributeValue(value) + "%"
        case .fittingSlots:
            return ECFormatters.attributeValue(value)
        case .trueTime:
            return ECFormatters.timeInterval(timeInterval: TimeInterval(value))
        case .modifierRelativePercent:
            return ECFormatters.attributeValue(value) + "%"
        case .newton:
            return ECFormatters.attributeValue(value) + " N"
        case .lightYear:
            return ECFormatters.attributeValue(value) + " ly"
        case .absolutePercent:
            return ECFormatters.attributeValue(value * 100) + "%"
        case .droneBandwidth:
            return ECFormatters.attributeValue(value) + " Mbit/s"
        case .hours:
            return ECFormatters.attributeValue(value) + " h"
        case .money:
            return ECFormatters.attributeValue(value) + " ISK"
        case .logisticalCapacity:
            return ECFormatters.attributeValue(value)
        case .astronomicalUnit:
            return ECFormatters.attributeValue(value) + " AU"
        case .slot:
            return ECFormatters.attributeValue(value)
        case .bool:
            switch value {
            case 1:
                return "True"
            default:
                return "False"
            }
        case .units:
            return ECFormatters.attributeValue(value) + " units"
        case .bonus:
            return ECFormatters.attributeValue(value) + "+"
        case .level:
            return ECFormatters.attributeValue(value)
        case .hardpoints:
            return ECFormatters.attributeValue(value)
        case .sex:
            if value == 1 {
                return "Male"
            } else if value == 2 {
                return "Unisex"
            } else if value == 3 {
                return "Female"
            } else {
                return "Unknown"
            }
        case .dateTime:
            return ECFormatters.attributeValue(value)
        case .unknown:
            return ECFormatters.attributeValue(value)
        }
    }
    
}
