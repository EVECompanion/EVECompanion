//
//  FittingsListView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import SwiftUI
import EVECompanionKit

struct FittingsListView: View {
    
    @StateObject var fittingManager: ECKFittingManager
    
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
        .overlay {
            if fittingManager.fittings.isEmpty && fittingManager.loadingState == .ready {
                ContentEmptyView(image: Image("Neocom/Fitting"),
                                 title: "No Fittings",
                                 subtitle: "New Fittings will appear here.")
            }
        }
    }
    
}
