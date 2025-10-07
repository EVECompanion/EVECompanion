//
//  FittingDetailDronesView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 22.06.25.
//

import SwiftUI
import EVECompanionKit

struct FittingDetailDronesView: View {
    
    private let fittingManager: ECKFittingManager
    @ObservedObject private var fitting: ECKCharacterFitting
    @State private var showSelectionView: Bool = false
    
    init(fittingManager: ECKFittingManager,
         fitting: ECKCharacterFitting) {
        self.fittingManager = fittingManager
        self.fitting = fitting
    }
    
    var body: some View {
        List {
            Section {
                Button {
                    showSelectionView = true
                } label: {
                    Label {
                        Text("Add Drone")
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
            }
            
            ForEach(fitting.drones) { drone in
                droneCell(for: drone)
            }
        }
        .sheet(isPresented: $showSelectionView) {
            ModuleSelectionView(moduleType: .drone,
                                targetShip: fitting.ship.item,
                                itemToReplace: nil) { selectedDrone in
                fitting.addDrone(newDrone: selectedDrone,
                                 manager: fittingManager)
            }
        }
    }
    
    @ViewBuilder
    func droneCell(for drone: ECKCharacterFittingItem) -> some View {
        HStack {
            ECImage(id: drone.item.typeId, category: .types)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text("\(drone.quantity)x " + drone.item.name)
                Text(drone.state.title)
            }
        }
    }
    
}

#Preview {
    FittingDetailDronesView(fittingManager: .init(character: .dummy, isPreview: true),
                            fitting: .dummyVNI)
}
