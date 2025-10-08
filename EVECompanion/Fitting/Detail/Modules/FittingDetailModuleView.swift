//
//  FittingDetailModuleView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 03.10.25.
//

import Foundation
import SwiftUI
import EVECompanionKit

struct FittingDetailModuleView: View {
    
    @ObservedObject var item: ECKCharacterFittingItem
    let fitting: ECKCharacterFitting
    
    var selectedStateBinding: Binding<ECKDogmaEffect.Category> {
        return .init {
            return item.state
        } set: { newState in
            Task {
                await fitting.calculateAttributes(skills: nil)
            }
            item.state = newState
        }
    }
    
    init(item: ECKCharacterFittingItem, fitting: ECKCharacterFitting) {
        self.item = item
        self.fitting = fitting
    }
    
    var body: some View {
        HStack {
            ECImage(id: item.item.typeId, category: .types)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(item.item.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Group {
                    if let optimalRange = item.attributes[54] {
                        moduleAttributeView(icon: "Fitting/targetingRange",
                                            title: "Optimal Range",
                                            unit: .length,
                                            attribute: optimalRange)
                    }
                    
                    if let falloff = item.attributes[158] {
                        moduleAttributeView(icon: "Fitting/falloff",
                                            title: "Falloff",
                                            unit: .length,
                                            attribute: falloff)
                    }
                    
                    if let maximumFlightTimeAttribute = item.charge?.attributes[281],
                       let chargeVelocityAttribute = item.charge?.attributes[37] {
                        let maximumFlightTime: Float = maximumFlightTimeAttribute.value ?? maximumFlightTimeAttribute.baseValue
                        let chargeVelocity: Float = chargeVelocityAttribute.value ?? chargeVelocityAttribute.baseValue
                        let flightRange = chargeVelocity * maximumFlightTime / Float(MSEC_PER_SEC)
                        let flightRangeAttribute = ECKCharacterFitting.FittingAttribute(id: -1, defaultValue: flightRange)
                        
                        moduleAttributeView(icon: "Fitting/targetingRange",
                                            title: "Missile Flight Range",
                                            unit: .length,
                                            attribute: flightRangeAttribute)
                    }
                    
                    if item.userSettableStates.count > 1 {
                        Picker(selection: selectedStateBinding) {
                            ForEach(item.userSettableStates) { state in
                                Text(state.title)
                                    .tag(state)
                            }
                        } label: {
                            Text("State")
                                .fontWeight(.bold)
                        }
                        .pickerStyle(.segmented)
                        .foregroundStyle(.primary)
                    }
                    
                    if let damageProfile = item.damageProfile,
                       damageProfile.containsDamage {
                        FittingDamageProfileView(damageProfile: damageProfile,
                                                 compactMode: true)
                        .foregroundStyle(.primary)
                    }
                }
                .foregroundStyle(.secondary)
            }
            
        }
    }
    
    @ViewBuilder
    private func moduleAttributeView(icon: String,
                                     title: String,
                                     unit: EVEUnit,
                                     attribute: ECKCharacterFitting.FittingAttribute) -> some View {
        HStack {
            Image(icon)
                .resizable()
                .frame(width: 20, height: 20)
            
            Text(title)
            
            Spacer()
            
            Text(unit.formatted(attribute.value ?? attribute.baseValue))
        }
    }
    
}

#Preview {
    List {
        FittingDetailModuleView(item: ECKCharacterFitting.dummyAvatar.highSlotModules.first!,
                                fitting: ECKCharacterFitting.dummyAvatar)
    }
}
