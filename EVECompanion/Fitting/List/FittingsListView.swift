//
//  FittingsListView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import SwiftUI
import EVECompanionKit

struct FittingsListView: View {
    
    @EnvironmentObject var coordinator: Coordinator
    @StateObject var fittingManager: ECKFittingManager
    @State var showsShipSelectionView: Bool = false
    
    var body: some View {
        Group {
            List {
                if fittingManager.localFittings.isEmpty == false {
                    Section("Local Fittings") {
                        ForEach(fittingManager.localFittings) { fitting in
                            NavigationLink(value: AppScreen.fittingDetail(fittingManager,
                                                                          fitting)) {
                                FittingCell(fitting: fitting)
                            }
                        }
                    }
                }
                
                if fittingManager.esiFittings.isEmpty == false {
                    Section("ESI Fittings") {
                        switch fittingManager.esiLoadingState {
                        case .ready,
                                .reloading:
                            ForEach(fittingManager.esiFittings) { fitting in
                                NavigationLink(value: AppScreen.fittingDetail(fittingManager,
                                                                              fitting)) {
                                    FittingCell(fitting: fitting)
                                }
                            }
                        case .loading:
                            ProgressView()
                            
                        case .error:
                            RetryButton {
                                await fittingManager.loadFittings()
                            }
                        }
                    }
                }
            }
            .refreshable {
                await fittingManager.loadFittings()
            }
            .searchable(text: $fittingManager.searchText)
        }
        .navigationTitle("Fittings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showsShipSelectionView = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showsShipSelectionView) {
            ShipSelectionView { ship in
                coordinator.push(screen: .fittingDetail(fittingManager, fittingManager.createFitting(with: ship)))
            }
        }
        .overlay {
            // TODO: Check for empty local fittings.
            if fittingManager.esiFittings.isEmpty && fittingManager.esiLoadingState == .ready {
                ContentEmptyView(image: Image("Neocom/Fitting"),
                                 title: "No Fittings",
                                 subtitle: "New Fittings will appear here.")
            }
        }
    }
    
}
