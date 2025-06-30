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
    let character: ECKCharacter
    
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
                    icon: "Fitting/subsystemslot")
            section(modules: moduleEntries(modules: fitting.highSlotModules,
                                           slotFlagPrefix: "HiSlot",
                                           slots: fitting.highSlots),
                    numberOfSlots: fitting.highSlots,
                    title: "High Slots",
                    slotType: "High",
                    icon: "Fitting/highslot")
            section(modules: moduleEntries(modules: fitting.midSlotModules,
                                           slotFlagPrefix: "MedSlot",
                                           slots: fitting.midSlots),
                    numberOfSlots: fitting.midSlots,
                    title: "Mid Slots",
                    slotType: "Mid",
                    icon: "Fitting/midslot")
            section(modules: moduleEntries(modules: fitting.lowSlotModules,
                                           slotFlagPrefix: "LoSlot",
                                           slots: fitting.lowSlots),
                    numberOfSlots: fitting.lowSlots,
                    title: "Low Slots",
                    slotType: "Low",
                    icon: "Fitting/lowslot")
            section(modules: moduleEntries(modules: fitting.rigs,
                                           slotFlagPrefix: "RigSlot",
                                           slots: fitting.rigSlots),
                    numberOfSlots: fitting.rigSlots,
                    title: "Rigs",
                    slotType: "Rig",
                    icon: "Fitting/rigslot")
        }
    }
    
    @ViewBuilder
    private func section(modules: [ModuleEntry],
                         numberOfSlots: Int,
                         title: String,
                         slotType: String,
                         icon: String) -> some View {
        if numberOfSlots > 0 {
            Section {
                ForEach(modules) { module in
                    switch module {
                    case .item(let item):
                        HStack {
                            ECImage(id: item.item.typeId, category: .types)
                                .frame(width: 40, height: 40)
                            
                            Text(item.item.name)
                        }
                        
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
                sectionHeader(text: title, icon: icon)
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
