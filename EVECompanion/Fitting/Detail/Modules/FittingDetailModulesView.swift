//
//  FittingDetailModulesView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 22.06.25.
//

import SwiftUI
import EVECompanionKit

struct FittingDetailModulesView: View {
    
    enum ModuleEntry: Identifiable {
        var id: UUID {
            switch self {
            case .item(let item):
                return item.id
            case .empty(let id):
                return id
            }
        }
        
        case item(ECKCharacterFittingItem)
        case empty(UUID)
    }
    
    @ObservedObject private var fitting: ECKCharacterFitting
    private let character: ECKCharacter
    @State private var chargeTargetItem: ECKCharacterFittingItem?
    
    init(character: ECKCharacter, fitting: ECKCharacterFitting) {
        self.character = character
        self.fitting = fitting
    }
    
    var body: some View {
        List {
            section(modules: moduleEntries(modules: fitting.subsystems,
                                           slotFlagPrefix: "SubSystemSlot",
                                           slots: fitting.subsystemSlots),
                    numberOfSlots: fitting.subsystemSlots,
                    title: "Subsystems",
                    slotType: "Subsystem",
                    icon: "Fitting/subsystemslot") {
                
            }
            section(modules: moduleEntries(modules: fitting.highSlotModules,
                                           slotFlagPrefix: "HiSlot",
                                           slots: fitting.highSlots),
                    numberOfSlots: fitting.highSlots,
                    title: "High Slots",
                    slotType: "High",
                    icon: "Fitting/highslot") {
                VStack {
                    Label {
                        Text("\(fitting.usedTurretHardPoints)/\(fitting.turretHardPoints)")
                    } icon: {
                        Image("Fitting/turret")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }

                    Label {
                        Text("\(fitting.usedLauncherHardPoints)/\(fitting.launcherHardPoints)")
                    } icon: {
                        Image("Fitting/launcher")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }

                }
            }
            section(modules: moduleEntries(modules: fitting.midSlotModules,
                                           slotFlagPrefix: "MedSlot",
                                           slots: fitting.midSlots),
                    numberOfSlots: fitting.midSlots,
                    title: "Mid Slots",
                    slotType: "Mid",
                    icon: "Fitting/midslot") {
                
            }
            section(modules: moduleEntries(modules: fitting.lowSlotModules,
                                           slotFlagPrefix: "LoSlot",
                                           slots: fitting.lowSlots),
                    numberOfSlots: fitting.lowSlots,
                    title: "Low Slots",
                    slotType: "Low",
                    icon: "Fitting/lowslot") {
                
            }
            section(modules: moduleEntries(modules: fitting.rigs,
                                           slotFlagPrefix: "RigSlot",
                                           slots: fitting.rigSlots),
                    numberOfSlots: fitting.rigSlots,
                    title: "Rigs",
                    slotType: "Rig",
                    icon: "Fitting/rigslot") {
                
            }
        }
        .sheet(item: $chargeTargetItem) { target in
            ChargeSelectionView(target: target.item) { selectedCharge in
                target.charge = .init(flag: target.flag,
                                      quantity: 1,
                                      item: selectedCharge)
                fitting.calculateAttributes(skills: character.skills ?? .empty)
            }
        }
    }
    
    @ViewBuilder
    private func section(modules: [ModuleEntry],
                         numberOfSlots: Int,
                         title: String,
                         slotType: String,
                         icon: String,
                         @ViewBuilder additionalHeaderView: (() -> some View)) -> some View {
        if numberOfSlots > 0 {
            Section {
                ForEach(modules) { module in
                    switch module {
                    case .item(let item):
                        HStack {
                            ECImage(id: item.item.typeId, category: .types)
                                .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading) {
                                Text(item.item.name)
                                
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
                                }
                                .foregroundStyle(.secondary)
                            }
                            
                        }
                        
                        if item.canUseCharges {
                            Button {
                                self.chargeTargetItem = item
                            } label: {
                                if let charge = item.charge {
                                    HStack {
                                        ECImage(id: charge.item.typeId, category: .types)
                                            .frame(width: 40, height: 40)
                                        
                                        Text(charge.item.name)
                                    }
                                } else {
                                    Text("Add Charge")
                                }
                            }
                        }
                        
//                        ForEach(item.fittingAttributes, id: \.attribute.id) { attribute in
//                            HStack {
//                                Text(attribute.attribute.displayName)
//                                Spacer()
//                                if let unit = attribute.attribute.unit {
//                                    Text(unit.formatted(attribute.fittingAttribute.value ?? 0))
//                                } else {
//                                    Text("\(attribute.fittingAttribute.value ?? 0)")
//                                }
//                            }
//                        }
                    
                    case .empty:
                        HStack {
                            Image(icon)
                                .resizable()
                                .frame(width: 40, height: 40)
                            
                            Text("Empty \(slotType) Slot")
                        }
                    }
                }
                
            } header: {
                HStack {
                    sectionHeader(text: title, icon: icon)
                    Spacer()
                    additionalHeaderView()
                }
            }
        }
    }
    
    @ViewBuilder
    private func sectionHeader(text: String, icon: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(icon)
                .resizable()
                .frame(width: 40, height: 40)
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
            
            Text(unit.formatted(attribute.value ?? 0))
        }
    }
    
    private func moduleEntries(modules: [ECKCharacterFittingItem],
                               slotFlagPrefix: String,
                               slots: Int) -> [ModuleEntry] {
        var result: [ModuleEntry] = []
        
        for index in 0..<slots {
            let flagString = "\(slotFlagPrefix)\(index)"
            guard let flag = ECKItemLocationFlag(rawValue: flagString) else {
                logger.error("Cannot get flag from \(flagString)")
                result.append(.empty(UUID()))
                continue
            }
            
            if let module = modules.first(where: { $0.flag == flag }) {
                result.append(.item(module))
            } else {
                result.append(.empty(UUID()))
            }
        }
        
        return result
    }
    
}

#Preview {
    FittingDetailModulesView(character: .dummy, fitting: .dummyAvatar)
}
