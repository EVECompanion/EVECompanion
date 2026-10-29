//
//  FittingDetailCargoView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 27.10.26.
//

import SwiftUI
import EVECompanionKit

struct FittingDetailCargoView: View {
    @ObservedObject var fitting: ECKCharacterFitting
    let manager: ECKFittingManager
    @State private var showItemSelection = false
    @State private var usedCargoVolume: Float

    init(fitting: ECKCharacterFitting, manager: ECKFittingManager) {
        self.fitting = fitting
        self.manager = manager
        self._usedCargoVolume = State(initialValue: fitting.usedCargoVolume)
    }

    var body: some View {
        List {
            if let capacity = fitting.cargo, capacity > 0 {
                Section {
                    HStack {
                        Image("Fitting/cargo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)

                        ProgressView(value: usedCargoVolume, total: capacity) {
                            HStack {
                                Text("Cargo")

                                Spacer()

                                let formattedValue = "\(ECFormatters.shortenedValue(usedCargoVolume, maximumFractionDigits: 1))/\(ECFormatters.shortenedValue(capacity, maximumFractionDigits: 1))"
                                Text("\(formattedValue) m³")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.footnote)
                        }
                        .progressViewStyle(.linear)
                        .animation(.spring, value: usedCargoVolume)
                        .tint(.blue)
                    }
                    .listRowBackground(usedCargoVolume > capacity ? Color.red : nil)
                }
            }

            Section {
                if fitting.cargoItems.isEmpty {
                    Text("Cargo hold is empty")
                        .foregroundStyle(.secondary)
                }
                ForEach(fitting.cargoItems) { cargoItem in
                    FittingDetailCargoItemRow(cargoItem: cargoItem,
                                              fitting: fitting,
                                              manager: manager) {
                        usedCargoVolume = fitting.usedCargoVolume
                    }
                }

                Button {
                    showItemSelection = true
                } label: {
                    Label {
                        Text("Add cargo item")
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showItemSelection) {
            ModuleSelectionView(moduleType: .cargo,
                                targetShip: fitting.ship.item,
                                itemToReplace: nil) { result in
                if case .item(let item) = result {
                    fitting.addCargoItem(item, manager: manager)
                    usedCargoVolume = fitting.usedCargoVolume
                }
            }
        }
        .onAppear {
            usedCargoVolume = fitting.usedCargoVolume
        }
    }
}

private struct FittingDetailCargoItemRow: View {
    @ObservedObject var cargoItem: ECKCharacterFittingItem
    let fitting: ECKCharacterFitting
    let manager: ECKFittingManager
    let cargoDidChange: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            NavigationLink(value: AppScreen.item(cargoItem.item)) {
                HStack(spacing: 12) {
                    ECImage(id: cargoItem.item.typeId, category: .types)
                        .frame(width: 40, height: 40)
                    Text(cargoItem.item.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                    
                    Spacer()
                    
                    Text(EVEUnit.volume.formatted(cargoItem.item.volume ?? 0))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 52)

                Text("\(EVEUnit.volume.formatted(cargoItem.totalVolume)) total")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Stepper(value: Binding(
                    get: { cargoItem.quantity },
                    set: {
                        fitting.setCargoItemQuantity(cargoItem, quantity: $0, manager: manager)
                        cargoDidChange()
                    }
                ), in: 1...999_999) {
                    Text("×\(cargoItem.quantity)")
                        .monospacedDigit()
                }
                .fixedSize()
                
                Spacer(minLength: 8)

                Button(role: .destructive) {
                    fitting.removeCargoItem(cargoItem, manager: manager)
                    cargoDidChange()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .accessibilityLabel("Remove cargo item")
            }
        }
    }
}

#Preview {
    FittingDetailCargoView(
        fitting: .dummyVNI,
        manager: .init(character: .dummy, isPreview: true)
    )
}
