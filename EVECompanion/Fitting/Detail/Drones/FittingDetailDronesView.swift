//
//  FittingDetailDronesView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 22.06.25.
//

import SwiftUI
import EVECompanionKit

struct FittingDetailDronesView: View {
    enum SheetItem: Identifiable {
        case add(ModuleSelectionView.ModuleType)
        case replace(ModuleSelectionView.ModuleType, ECKCharacterFittingItem)

        var id: String {
            switch self {
            case .add(let moduleType):
                return "add-\(moduleType.id)"
            case .replace(let moduleType, let item):
                return "replace-\(moduleType.id)-\(item.id.uuidString)"
            }
        }
    }
    
    private let fittingManager: ECKFittingManager
    @ObservedObject private var fitting: ECKCharacterFitting
    @State private var sheetItem: SheetItem?
    
    init(fittingManager: ECKFittingManager,
         fitting: ECKCharacterFitting) {
        self.fittingManager = fittingManager
        self.fitting = fitting
    }
    
    var body: some View {
        List {
            if fitting.canUseDrones {
                Section {
                    Button {
                        sheetItem = .add(.drone)
                    } label: {
                        Label {
                            Text("Add Drone")
                        } icon: {
                            Image(systemName: "plus")
                        }
                    }
                }

                ForEach(fitting.drones) { drone in
                    FittingDetailDroneView(fitting: fitting,
                                           fittingManager: fittingManager,
                                           drone: drone) { drone in
                        sheetItem = .replace(.drone, drone)
                    }
                }
            }

            if fitting.canUseFighters {
                ForEach(fitting.availableFighterTypes) { fighterType in
                    Section {
                        Button {
                            sheetItem = .add(.fighter(fighterType))
                        } label: {
                            Label {
                                Text("Add \(fighterType.title) Fighter")
                            } icon: {
                                Image(systemName: "plus")
                            }
                        }
                        .disabled(fitting.canAddFighter(ofType: fighterType) == false)

                        ForEach(fitting.fighters.filter({ $0.item.fighterType == fighterType })) { fighter in
                            FittingDetailDroneView(fitting: fitting,
                                                   fittingManager: fittingManager,
                                                   drone: fighter) { fighter in
                                sheetItem = .replace(.fighter(fighterType), fighter)
                            }
                        }
                    } header: {
                        Text("\(fighterType.pluralTitle) (\(fitting.usedFighterTubes(for: fighterType))/\(fitting.maxFighterSquadrons(for: fighterType)))")
                    }
                }
            }
        }
        .sheet(item: $sheetItem) { sheetItem in
            let config = sheetConfiguration(for: sheetItem)

            ModuleSelectionView(moduleType: config.moduleType,
                                targetShip: fitting.ship.item,
                                itemToReplace: config.itemToReplace?.item) { result in
                switch result {
                case .item(let selectedItem):
                    if let itemToReplace = config.itemToReplace {
                        if itemToReplace.item.isFighter {
                            fitting.replaceFighter(itemToReplace,
                                                   with: selectedItem,
                                                   manager: fittingManager)
                        } else {
                            fitting.replaceDrone(itemToReplace,
                                                 with: selectedItem,
                                                 manager: fittingManager)
                        }
                    } else if selectedItem.isFighter {
                        fitting.addFighter(newFighter: selectedItem,
                                           manager: fittingManager)
                    } else {
                        fitting.addDrone(newDrone: selectedItem,
                                         manager: fittingManager)
                    }
                case .remove:
                    if let itemToReplace = config.itemToReplace {
                        if itemToReplace.item.isFighter {
                            fitting.removeFighter(itemToReplace, manager: fittingManager)
                        } else {
                            fitting.removeDrone(itemToReplace, manager: fittingManager)
                        }
                    }
                }
            }
        }
    }

    private func sheetConfiguration(for sheetItem: SheetItem) -> (moduleType: ModuleSelectionView.ModuleType, itemToReplace: ECKCharacterFittingItem?) {
        switch sheetItem {
        case .add(let addType):
            return (moduleType: addType, itemToReplace: nil)
        case .replace(let replaceType, let item):
            return (moduleType: replaceType, itemToReplace: item)
        }
    }
    
}

#Preview {
    FittingDetailDronesView(fittingManager: .init(character: .dummy, isPreview: true),
                            fitting: .dummyVNI)
}
