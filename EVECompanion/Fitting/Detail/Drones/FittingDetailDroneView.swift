//
//  FittingDetailDroneView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 09.10.25.
//

import SwiftUI
import EVECompanionKit

struct FittingDetailDroneView: View {
    
    let fittingManager: ECKFittingManager
    @ObservedObject private var fitting: ECKCharacterFitting
    @ObservedObject private var drone: ECKCharacterFittingItem
    var selectedStateBinding: Binding<ECKDogmaEffect.Category> {
        return .init {
            return drone.state
        } set: { newState in
            Task {
                await fitting.calculateAttributes(skills: nil)
            }
            drone.state = newState
        }
    }
    
    init(fitting: ECKCharacterFitting,
         fittingManager: ECKFittingManager,
         drone: ECKCharacterFittingItem) {
        self.fitting = fitting
        self.fittingManager = fittingManager
        self.drone = drone
    }
    
    var body: some View {
        HStack {
            ECImage(id: drone.item.typeId, category: .types)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text("\(drone.quantity)x \(drone.item.name)")
                    .font(.headline)
                    .fontWeight(.bold)
                
                if drone.userSettableStates.count > 1 {
                    Picker(selection: selectedStateBinding) {
                        ForEach(drone.userSettableStates) { state in
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
            }
            
            amountButtons
        }
    }
    
    @ViewBuilder
    var amountButtons: some View {
        HStack {
            Button {
                if drone.quantity == 1 {
                    fitting.removeDrone(drone, manager: fittingManager)
                } else {
                    drone.quantity -= 1
                    fitting.objectWillChange.send()
                    fittingManager.saveFitting(fitting)
                }
            } label: {
                Image(systemName: "minus")
                    .padding()
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .disabled(drone.quantity <= 0)

            Divider()
            
            Button {
                drone.quantity += 1
                fitting.objectWillChange.send()
                fittingManager.saveFitting(fitting)
            } label: {
                Image(systemName: "plus")
                    .padding()
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .disabled(drone.quantity >= 5)
        }
        .background {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(UIColor.secondarySystemBackground))
        }
    }
    
}

#Preview {
    FittingDetailDronesView(fittingManager: .init(character: .dummy, isPreview: true),
                            fitting: .dummyVNI)
}
