//
//  EVEUnit.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 05.04.25.
//

import Foundation

public enum EVEUnit: String, Sendable {
    
    case length = "Length"
    case mass = "Mass"
    case time = "Time"
    case electricCurrent = "Electric Current"
    case temperature = "Temperature"
    case amountOfSubstance = "Amount Of Substance"
    case luminousIntensity = "Luminous Intensity"
    case area = "Area"
    case volume = "Volume"
    case speed = "Speed"
    case acceleration = "Acceleration"
    case waveNumber = "Wave Number"
    case massDensity = "Mass Density"
    case specificVolume = "Specific Volume"
    case currentDensity = "Current Density"
    case magneticFieldStrength = "Magnetic Field Strength"
    case amountOfSubstanceConcentration = "Amount-Of-Substance Concentration"
    case luminance = "Luminance"
    case massFraction = "Mass Fraction"
    case milliseconds = "Milliseconds"
    case millimeters = "Millimeters"
    case megaPascals = "MegaPascals"
    case multiplier = "Multiplier"
    case percentage = "Percentage"
    case teraflops = "Teraflops"
    case megawatts = "MegaWatts"
    case inverseAbsolutePercent = "Inverse Absolute Percent"
    case modifierPercent = "Modifier Percent"
    case inversedModifierPercent = "Inversed Modifier Percent"
    case radiansPerSecond = "Radians/Second"
    case hitpoints = "Hitpoints"
    case capacitorUnits = "capacitor units"
    case groupId = "groupID"
    case typeId = "typeID"
    case sizeClass = "Sizeclass"
    case oreUnits = "Ore units"
    case attributeId = "attributeID"
    case attributePoints = "attributePoints"
    case realPercent = "realPercent"
    case fittingSlots = "Fitting slots"
    case trueTime = "trueTime"
    case modifierRelativePercent = "Modifier Relative Percent"
    case newton = "Newton"
    case lightYear = "Light Year"
    case absolutePercent = "Absolute Percent"
    case droneBandwidth = "Drone bandwidth"
    case hours = "Hours"
    case money = "Money"
    case logisticalCapacity = "Logistical Capacity"
    case astronomicalUnit = "Astronomical Unit"
    case slot = "Slot"
    case bool = "Boolean"
    case units = "Units"
    case bonus = "Bonus"
    case level = "Level"
    case hardpoints = "Hardpoints"
    case sex = "Sex"
    case dateTime = "Datetime"
    case warpSpeed = "Warp speed"
    
    case unknown
    
    public init(_ valueString: String) {
        guard let value = EVEUnit(rawValue: valueString) else {
            logger.error("Cannot parse eve unit \(valueString)")
            self = .unknown
            return
        }
        
        self = value
    }
    
    public func formatted(_ value: Float) -> String {
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
            return ECFormatters.attributeValue(100 - (value * 100), maximumFractionDigits: 1) + "%"
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
            return ECFormatters.shortenedValue(value, maximumFractionDigits: 0) + " HP"
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
        case .warpSpeed:
            return ECFormatters.attributeValue(value) + " AU/s"
        }
    }
    
}
