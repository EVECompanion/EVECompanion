//
//  FittingDetailBoostersView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 29.10.26.
//

import SwiftUI
import EVECompanionKit

struct FittingDetailBoostersView: View {

    @ObservedObject private var fitting: ECKCharacterFitting
    let fittingManager: ECKFittingManager
    @State private var isSelectingBooster = false

    init(fitting: ECKCharacterFitting, fittingManager: ECKFittingManager) {
        self.fitting = fitting
        self.fittingManager = fittingManager
    }

    var body: some View {
        List {
            Section("Fitted Boosters") {
                if fitting.boosters.isEmpty {
                    Text("No boosters fitted")
                        .foregroundStyle(.secondary)
                }

                ForEach(fitting.boosters) { booster in
                    HStack {
                        NavigationLink(value: AppScreen.item(booster.item)) {
                            HStack {
                                ECImage(id: booster.item.typeId, category: .types)
                                    .frame(width: 40, height: 40)
                                VStack(alignment: .leading) {
                                    Text(booster.item.name)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    if let slot = ECKSDEManager.shared.boosterSlot(for: booster.item.typeId) {
                                        Text("Booster Slot \(slot)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        Button(role: .destructive) {
                            fitting.removeBooster(booster, manager: fittingManager)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Remove \(booster.item.name)")
                    }
                }
            }

            Section {
                Button {
                    isSelectingBooster = true
                } label: {
                    Label("Add Booster", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isSelectingBooster) {
            FittingBoosterSearchView { booster in
                fitting.addBooster(newBooster: booster, manager: fittingManager)
            }
        }
    }
}

private struct FittingBoosterSearchView: View {

    @Environment(\.dismiss) private var dismiss
    let completion: (ECKItem) -> Void
    @State private var searchString = ""
    @State private var itemToDisplay: ECKItem?

    private var boosters: [ECKItem] {
        ECKSDEManager.shared.getBoosters(text: searchString)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(boosters) { booster in
                    Button {
                        completion(booster)
                        dismiss()
                    } label: {
                        HStack {
                            ECImage(id: booster.typeId, category: .types)
                                .frame(width: 40, height: 40)
                            VStack(alignment: .leading) {
                                Text(booster.name)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                if let slot = ECKSDEManager.shared.boosterSlot(for: booster.typeId) {
                                    Text("Booster Slot \(slot)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button {
                                itemToDisplay = booster
                            } label: {
                                Image(systemName: "info.circle")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .searchable(text: $searchString)
            .navigationTitle("Select Booster")
            .sheet(item: $itemToDisplay) { item in
                CoordinatorView(initialScreen: .item(item))
            }
        }
    }
}
