//
//  PlanetaryColoniesView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 21.10.24.
//

import SwiftUI
import EVECompanionKit

struct PlanetaryColoniesView: View {
    
    @ObservedObject var colonyManager: ECKPlanetaryColonyManager
    
    var body: some View {
        Group {
            switch colonyManager.loadingState {
            case .ready,
                 .reloading:
                if colonyManager.colonies.isEmpty {
                    ContentEmptyView(image: Image("Neocom/PlanetaryColonies"),
                                     title: "No Planetary Colonies",
                                     subtitle: "Your planetary colonies will appear here.")
                } else {
                    List(colonyManager.colonies, id: \.colony.planet.planetId) { colony in
                        Section {
                            PlanetaryColonyCell(colony: colony)
                        }
                    }
                    .refreshable {
                        await colonyManager.loadColonies()
                    }
                }
                
            case .loading:
                ProgressView()
                
            case .error:
                RetryButton {
                    await colonyManager.loadColonies()
                }
            }
        }
        .navigationTitle("Planetary Colonies")
        .onAppear {
            Task {
                await colonyManager.loadColonies()
            }
        }
        .refreshable {
            await colonyManager.loadColonies()
        }
    }
    
}

#Preview {
    NavigationStack {
        PlanetaryColoniesView(colonyManager: .init(character: .dummy,
                                                   isPreview: true))
    }
}
