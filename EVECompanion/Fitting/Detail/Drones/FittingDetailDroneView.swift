//
//  FittingDetailDroneView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 09.10.25.
//

import SwiftUI
import EVECompanionKit
import Combine

struct FittingDetailDroneView: View {
    
    let fittingManager: ECKFittingManager
    @ObservedObject private var fitting: ECKCharacterFitting
    @ObservedObject private var drone: ECKCharacterFittingItem
    private let openSelection: (ECKCharacterFittingItem) -> Void
    private var selectedStateBinding: Binding<ECKDogmaEffect.Category> {
        .init {
            drone.state
        } set: { newState in
            drone.state = newState
            Task {
                await fitting.calculateAttributes(skills: nil)
            }
        }
    }
    
    init(fitting: ECKCharacterFitting,
         fittingManager: ECKFittingManager,
         drone: ECKCharacterFittingItem,
         openSelection: @escaping (ECKCharacterFittingItem) -> Void) {
        self.fittingManager = fittingManager
        self.fitting = fitting
        self.drone = drone
        self.openSelection = openSelection
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Button {
                    openSelection(drone)
                } label: {
                    HStack {
                        ECImage(id: drone.item.typeId, category: .types)
                            .frame(width: 40, height: 40)
                        
                        Text("\(drone.quantity)x \(drone.item.name)")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .buttonStyle(.plain)

                if drone.userSettableStates.count > 1 {
                    Picker("State", selection: selectedStateBinding) {
                        ForEach(drone.userSettableStates) { state in
                            Text(state.title)
                                .tag(state)
                        }
                    }
                    .pickerStyle(.segmented)
                    .foregroundStyle(.primary)
                }
            }
            
            actionButtons
        }
    }
    
    @ViewBuilder
    var actionButtons: some View {
        if drone.flag == .DroneBay {
            HStack {
                Button {
                    if drone.quantity > 1 {
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
                .disabled(drone.quantity <= 1)

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
    
}

#Preview {
    FittingDetailDronesView(fittingManager: .init(character: .dummy, isPreview: true),
                            fitting: .dummyVNI)
}
