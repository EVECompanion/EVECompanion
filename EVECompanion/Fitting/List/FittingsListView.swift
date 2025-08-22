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
            switch fittingManager.loadingState {
            case .ready,
                 .reloading:
                List(fittingManager.fittings) { fitting in
                    NavigationLink(value: AppScreen.fittingDetail(fittingManager.character,
                                                                  fitting)) {
                        FittingCell(fitting: fitting)
                    }
                }
                .refreshable {
                    await fittingManager.loadFittings()
                }
                .searchable(text: $fittingManager.searchText)
                
            case .loading:
                ProgressView()
                
            case .error:
                RetryButton {
                    await fittingManager.loadFittings()
                }
                
            }
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
                coordinator.push(screen: .fittingDetail(fittingManager.character, .init(ship: ship)))
            }
        }
        .overlay {
            if fittingManager.fittings.isEmpty && fittingManager.loadingState == .ready {
                ContentEmptyView(image: Image("Neocom/Fitting"),
                                 title: "No Fittings",
                                 subtitle: "New Fittings will appear here.")
            }
        }
    }
    
}
