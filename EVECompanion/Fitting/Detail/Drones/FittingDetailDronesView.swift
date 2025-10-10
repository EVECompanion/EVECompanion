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
                FittingDetailDroneView(fitting: fitting,
                                       fittingManager: fittingManager,
                                       drone: drone)
            }
        }
        .sheet(isPresented: $showSelectionView) {
            ModuleSelectionView(moduleType: .drone,
                                targetShip: fitting.ship.item,
                                itemToReplace: nil) { result in
                switch result {
                case .item(let selectedDrone):
                    fitting.addDrone(newDrone: selectedDrone,
                                     manager: fittingManager)
                case .remove:
                    return
                }
            }
        }
    }
    
}

#Preview {
    FittingDetailDronesView(fittingManager: .init(character: .dummy, isPreview: true),
                            fitting: .dummyVNI)
}
