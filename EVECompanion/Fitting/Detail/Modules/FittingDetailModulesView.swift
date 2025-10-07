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
    
    enum AlertItem: Identifiable {
        var id: String {
            switch self {
            case .addModuleError(let error):
                return "addModuleError-\(error.id)"
            case .shouldBatchInsert(charge: let charge, target: let target):
                return "shouldBatchInsert-\(charge.id)-\(target.id)"
            }
        }
        
        var title: String {
            switch self {
            case .addModuleError:
                return "Error adding module"
            case .shouldBatchInsert:
                return "Batch insert charge?"
            }
        }
        
        var text: String {
            switch self {
            case .addModuleError(let error):
                return error.text
            case .shouldBatchInsert(charge: let charge, target: let target):
                return "Do you want to batch insert \(charge.name) into all \(target.item.name) modules?"
            }
        }
        
        case addModuleError(ECKAddModuleError)
        case shouldBatchInsert(charge: ECKItem, target: ECKCharacterFittingItem)
    }
    
    let fittingManager: ECKFittingManager
    @ObservedObject private var fitting: ECKCharacterFitting
    private let character: ECKCharacter
    @State private var sheetItem: SheetItem?
    @State private var alertItem: AlertItem?
    @State private var showAlert: Bool = false
    
    init(character: ECKCharacter, fitting: ECKCharacterFitting, manager: ECKFittingManager) {
        self.character = character
        self.fitting = fitting
        self.fittingManager = manager
    }
    
    var body: some View {
        List {
            section(modules: moduleEntries(modules: fitting.subsystems,
                                           slotFlagPrefix: "SubSystemSlot",
                                           slots: 4,
                                           usedSlots: fitting.subsystems.count),
                    moduleType: .subsystem,
                    numberOfSlots: fitting.subsystemSlots,
                    numberOfUsedSlots: fitting.subsystems.count,
                    title: "Subsystems",
                    slotType: .subsystem,
                    icon: "Fitting/subsystemslot") {
                
            }
            section(modules: moduleEntries(modules: fitting.highSlotModules,
                                           slotFlagPrefix: "HiSlot",
                                           slots: fitting.highSlots,
                                           usedSlots: fitting.highSlotModules.count),
                    moduleType: .module(.high),
                    numberOfSlots: fitting.highSlots,
                    numberOfUsedSlots: fitting.highSlotModules.count,
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
                                           slots: fitting.midSlots,
                                           usedSlots: fitting.midSlotModules.count),
                    moduleType: .module(.mid),
                    numberOfSlots: fitting.midSlots,
                    numberOfUsedSlots: fitting.midSlotModules.count,
                    title: "Mid Slots",
                    slotType: .mid,
                    icon: "Fitting/midslot") {
                
            }
            section(modules: moduleEntries(modules: fitting.lowSlotModules,
                                           slotFlagPrefix: "LoSlot",
                                           slots: fitting.lowSlots,
                                           usedSlots: fitting.lowSlotModules.count),
                    moduleType: .module(.low),
                    numberOfSlots: fitting.lowSlots,
                    numberOfUsedSlots: fitting.lowSlotModules.count,
                    title: "Low Slots",
                    slotType: .low,
                    icon: "Fitting/lowslot") {
                
            }
            section(modules: moduleEntries(modules: fitting.rigs,
                                           slotFlagPrefix: "RigSlot",
                                           slots: fitting.rigSlots,
                                           usedSlots: fitting.rigs.count),
                    moduleType: .rig,
                    numberOfSlots: fitting.rigSlots,
                    numberOfUsedSlots: fitting.rigs.count,
                    title: "Rigs",
                    slotType: .rig,
                    icon: "Fitting/rigslot") {
                
            }
        }
        .alert(alertItem?.title ?? "",
               isPresented: $showAlert,
               presenting: $alertItem) { item in
            switch item.wrappedValue {
            case .addModuleError:
                Button("Ok") {
                    item.wrappedValue = nil
                }
            case .shouldBatchInsert(charge: let charge, target: let target):
                Button("Yes") {
                    fitting.addCharge(charge, into: target, batchInsert: true)
                    item.wrappedValue = nil
                }
                
                Button(role: .cancel) {
                    fitting.addCharge(charge, into: target, batchInsert: false)
                    item.wrappedValue = nil
                } label: {
                    Text("No")
                }
            case .none:
                EmptyView()
            }
        } message: { item in
            Text(item.wrappedValue?.text ?? "")
        }
        .sheet(item: $sheetItem) { item in
            switch item {
            case .chargeSelection(let target):
                ChargeSelectionView(target: target.item) { selectedCharge in
                    if fitting.canBatchInsert(charge: selectedCharge, into: target) {
                        self.alertItem = .shouldBatchInsert(charge: selectedCharge,
                                                            target: target)
                        self.showAlert = true
                    } else {
                        fitting.addCharge(selectedCharge, into: target, batchInsert: false)
                    }
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
                        self.alertItem = .addModuleError(error)
                        self.showAlert = true
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
                        self.alertItem = .addModuleError(error)
                        self.showAlert = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func section(modules: [ModuleEntry],
                         moduleType: ModuleSelectionView.ModuleType,
                         numberOfSlots: Int,
                         numberOfUsedSlots: Int,
                         title: String,
                         slotType: ECKCharacterFitting.ModuleSlotType,
                         icon: String,
                         @ViewBuilder additionalHeaderView: (() -> some View)) -> some View {
        if max(numberOfSlots, numberOfUsedSlots) > 0 {
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
                    sectionHeader(text: title,
                                  secondaryText: moduleType.id == ModuleSelectionView.ModuleType.subsystem.id ? nil : "\(numberOfUsedSlots)/\(numberOfSlots)",
                                  icon: icon,
                                  showWarning: numberOfUsedSlots > numberOfSlots)
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
    private func sectionHeader(text: String,
                               secondaryText: String?,
                               icon: String,
                               showWarning: Bool) -> some View {
        Label {
            HStack {
                Text(text)
                
                if let secondaryText {
                    Text(secondaryText)
                }
            }
        } icon: {
            Image(icon)
                .resizable()
                .frame(width: 40, height: 40)
        }
        .padding(8)
        .background {
            if showWarning {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.red)
            }
        }
    }
    
    private func moduleEntries(modules: [ECKCharacterFittingItem],
                               slotFlagPrefix: String,
                               slots: Int,
                               usedSlots: Int) -> [ModuleEntry] {
        var result: [ModuleEntry] = []
        
        for index in 0..<max(slots, usedSlots) {
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
