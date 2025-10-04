//
//  FittingDetailModulesView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 22.06.25.
//

import SwiftUI
import EVECompanionKit

struct FittingDetailModulesView: View {
    
    enum ModuleEntry: Identifiable, Hashable {
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
    
    enum SheetItem: Identifiable {
        case chargeSelection(target: ECKCharacterFittingItem)
        case moduleSelection(moduleType: ModuleSelectionView.ModuleType)
        case moduleReplacement(moduleType: ModuleSelectionView.ModuleType, moduleToReplace: ECKCharacterFittingItem)
        
        var id: String {
            switch self {
            case .chargeSelection(let target):
                return target.id.uuidString
            case .moduleSelection(let moduleType):
                return moduleType.id
            case .moduleReplacement(moduleType: let moduleType, moduleToReplace: let moduleToReplace):
                return "\(moduleType.id)-\(moduleToReplace.id.uuidString)"
            }
        }
    }
    
    let fittingManager: ECKFittingManager
    @ObservedObject private var fitting: ECKCharacterFitting
    private let character: ECKCharacter
    @State private var sheetItem: SheetItem?
    @State private var addModuleError: ECKAddModuleError?
    @State private var showModuleErrorDialog: Bool = false
    
    init(character: ECKCharacter, fitting: ECKCharacterFitting, manager: ECKFittingManager) {
        self.character = character
        self.fitting = fitting
        self.fittingManager = manager
    }
    
    var body: some View {
        List {
            section(modules: moduleEntries(modules: fitting.subsystems,
                                           slotFlagPrefix: "SubSystemSlot",
                                           slots: fitting.subsystemSlots),
                    moduleType: .subsystem,
                    numberOfSlots: fitting.subsystemSlots,
                    title: "Subsystems",
                    slotType: .subsystem,
                    icon: "Fitting/subsystemslot") {
                
            }
            section(modules: moduleEntries(modules: fitting.highSlotModules,
                                           slotFlagPrefix: "HiSlot",
                                           slots: fitting.highSlots),
                    moduleType: .module(.high),
                    numberOfSlots: fitting.highSlots,
                    title: "High Slots",
                    slotType: .high,
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
                    moduleType: .module(.mid),
                    numberOfSlots: fitting.midSlots,
                    title: "Mid Slots",
                    slotType: .mid,
                    icon: "Fitting/midslot") {
                
            }
            section(modules: moduleEntries(modules: fitting.lowSlotModules,
                                           slotFlagPrefix: "LoSlot",
                                           slots: fitting.lowSlots),
                    moduleType: .module(.low),
                    numberOfSlots: fitting.lowSlots,
                    title: "Low Slots",
                    slotType: .low,
                    icon: "Fitting/lowslot") {
                
            }
            section(modules: moduleEntries(modules: fitting.rigs,
                                           slotFlagPrefix: "RigSlot",
                                           slots: fitting.rigSlots),
                    moduleType: .rig,
                    numberOfSlots: fitting.rigSlots,
                    title: "Rigs",
                    slotType: .rig,
                    icon: "Fitting/rigslot") {
                
            }
        }
        .alert("Error adding module",
               isPresented: $showModuleErrorDialog,
               presenting: $addModuleError) { error in
            Button("Ok") {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.wrappedValue?.text ?? "")
        }
        .sheet(item: $sheetItem) { item in
            switch item {
            case .chargeSelection(let target):
                ChargeSelectionView(target: target.item) { selectedCharge in
                    target.charge = .init(flag: target.flag,
                                          quantity: 1,
                                          item: selectedCharge)
                    fitting.calculateAttributes(skills: character.skills ?? .empty)
                }
            case .moduleSelection(let moduleType):
                ModuleSelectionView(moduleType: moduleType,
                                    targetShip: fitting.ship.item,
                                    itemToReplace: nil) { item in
                    do throws(ECKAddModuleError) {
                        try fitting.addModule(item: item,
                                              skills: character.skills ?? .empty,
                                              moduleToReplace: nil,
                                              manager: fittingManager)
                    } catch {
                        self.addModuleError = error
                        self.showModuleErrorDialog = true
                    }
                }
            case .moduleReplacement(moduleType: let moduleType, moduleToReplace: let moduleToReplace):
                ModuleSelectionView(moduleType: moduleType,
                                    targetShip: fitting.ship.item,
                                    itemToReplace: moduleToReplace.item) { item in
                    do throws(ECKAddModuleError) {
                        try fitting.addModule(item: item,
                                              skills: character.skills ?? .empty,
                                              moduleToReplace: moduleToReplace,
                                              manager: fittingManager)
                    } catch {
                        self.addModuleError = error
                        self.showModuleErrorDialog = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func section(modules: [ModuleEntry],
                         moduleType: ModuleSelectionView.ModuleType,
                         numberOfSlots: Int,
                         title: String,
                         slotType: ECKCharacterFitting.ModuleSlotType,
                         icon: String,
                         @ViewBuilder additionalHeaderView: (() -> some View)) -> some View {
        if numberOfSlots > 0 {
            Section {
                ForEach(modules) { module in
                    switch module {
                    case .item(let item):
                        itemCell(for: item,
                                 moduleType: moduleType)
                    
                    case .empty:
                        emptySlotCell(moduleType: moduleType,
                                      slotType: slotType,
                                      icon: icon)
                        
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
    private func itemCell(for item: ECKCharacterFittingItem,
                          moduleType: ModuleSelectionView.ModuleType) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    self.sheetItem = .moduleReplacement(moduleType: moduleType,
                                                        moduleToReplace: item)
                } label: {
                    FittingDetailModuleView(item: item, fitting: fitting)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button {
                    fitting.removeModule(item: item, manager: fittingManager)
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
            }
            
            if item.canUseCharges {
                Divider()
                
                HStack {
                    Button {
                        self.sheetItem = .chargeSelection(target: item)
                    } label: {
                        if let charge = item.charge {
                            HStack {
                                ECImage(id: charge.item.typeId, category: .types)
                                    .frame(width: 40, height: 40)
                                
                                Text(charge.item.name)
                            }
                        } else {
                            Text("Add Charge")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .buttonStyle(.borderless)
                    
                    Spacer()
                    
                    if item.charge != nil {
                        Button {
                            withAnimation {
                                fitting.removeCharge(from: item, manager: fittingManager)
                            }
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .animation(.spring, value: item.charge)
    }
    
    @ViewBuilder
    private func emptySlotCell(moduleType: ModuleSelectionView.ModuleType,
                               slotType: ECKCharacterFitting.ModuleSlotType,
                               icon: String) -> some View {
        Button {
            self.sheetItem = .moduleSelection(moduleType: moduleType)
        } label: {
            HStack {
                Image(icon)
                    .resizable()
                    .frame(width: 40, height: 40)
                
                Text("Empty \(slotType.name) Slot")
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

private extension ECKCharacterFitting.ModuleSlotType {
    var name: String {
        switch self {
        case .rig:
            return "Rig"
        case .subsystem:
            return "Subsystem"
        case .high:
            return "High"
        case .mid:
            return "Mid"
        case .low:
            return "Low"
        }
    }
}

#Preview {
    FittingDetailModulesView(character: .dummy,
                             fitting: .dummyAvatar,
                             manager: .init(character: .dummy,
                                            isPreview: true))
}
