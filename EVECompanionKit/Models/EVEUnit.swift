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
    
    case unknown
    
    public init(_ valueString: String) {
        guard let value = EVEUnit(rawValue: valueString) else {
            logger.error("Cannot parse eve unit \(valueString)")
            self = .unknown
            return
        }
        
        self = value
    }
    
}
