//
//  FittingDetailInfoView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import SwiftUI
import EVECompanionKit

struct FittingDetailInfoView: View {
    
    @ObservedObject private var fitting: ECKCharacterFitting
    let character: ECKCharacter
    
    init(character: ECKCharacter, fitting: ECKCharacterFitting) {
        self.character = character
        self.fitting = fitting
    }
    
    var body: some View {
        List {
            if let resistances = fitting.resistances {
                Section("Resistances") {
                    FittingResistancesView(resistances: resistances)
                }
            }

            if [fitting.maximumLockedTargets,
                fitting.maximumTargetingRange,
                fitting.scanResolution,
                fitting.sensorStrength].compactMap({ $0 }).isEmpty == false {
                Section("Targeting") {
                    if let maximumLockedTargets = fitting.maximumLockedTargets {
                        keyValueCell(attribute: "Maximum Locked Targets",
                                     valueText: ECFormatters.attributeValue(maximumLockedTargets,
                                                                            maximumFractionDigits: 0),
                                     icon: "Fitting/maxTargets")
                    }
                    
                    if let maximumTargetRange = fitting.maximumTargetingRange {
                        keyValueCell(attribute: "Maximum Targeting Range",
                                     valueText: ECFormatters.attributeValue(maximumTargetRange / 1000,
                                                                            maximumFractionDigits: 1) + " km",
                                     icon: "Fitting/targetingRange")
                    }
                    
                    if let scanResolution = fitting.scanResolution {
                        keyValueCell(attribute: "Scan Resolution",
                                     valueText: ECFormatters.attributeValue(scanResolution,
                                                                            maximumFractionDigits: 0) + " mm",
                                     icon: "Fitting/scanRes")
                    }
                    
                    if let sensorStrength = fitting.sensorStrength {
                        keyValueCell(attribute: "Sensor Strength",
                                     valueText: ECFormatters.attributeValue(sensorStrength,
                                                                            maximumFractionDigits: 1),
                                     icon: "Fitting/scanRes")
                    }
                }
            }
            
            if [fitting.warpSpeed, fitting.alignTime, fitting.signatureRadius, fitting.cargo].compactMap({ $0 }).isEmpty == false {
                Section("Misc") {
                    if let warpSpeed = fitting.warpSpeed {
                        keyValueCell(attribute: "Warp Speed",
                                     valueText: ECFormatters.attributeValue(warpSpeed,
                                                                            maximumFractionDigits: 2) + " AU/s",
                                     icon: "Fitting/warpSpeed")
                    }
                    
                    if let alignTime = fitting.alignTime {
                        keyValueCell(attribute: "Align Time",
                                     valueText: ECFormatters.attributeValue(alignTime,
                                                                            maximumFractionDigits: 2) + " s",
                                     icon: "Fitting/alignTime")
                    }
                    
                    if let signatureRadius = fitting.signatureRadius {
                        keyValueCell(attribute: "SignatureRadius",
                                     valueText: ECFormatters.attributeValue(signatureRadius,
                                                                            maximumFractionDigits: 1),
                                     icon: "Fitting/signatureRadius")
                    }
                    
                    if let cargo = fitting.cargo {
                        keyValueCell(attribute: "Cargo",
                                     valueText: EVEUnit.volume.formatted(cargo),
                                     icon: "Fitting/cargo")
                    }
                }
            }
            
            ForEach(fitting.fittingAttributes, id: \.attribute.id) { attribute in
                HStack {
                    Text(attribute.attribute.displayName)
                    Spacer()
                    if let unit = attribute.attribute.unit {
                        Text(unit.formatted(attribute.fittingAttribute.value ?? 0))
                    } else {
                        Text("\(attribute.fittingAttribute.value ?? 0)")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func keyValueCell(attribute: String, valueText: String, icon: String) -> some View {
        Label {
            HStack {
                Text(attribute)
                Spacer()
                Text(valueText)
            }
        } icon: {
            Image(icon)
                .resizable()
                .frame(width: 32, height: 32)
        }
    }
    
}

#Preview {
    FittingDetailInfoView(character: .dummy, fitting: .dummyAvatar)
}
