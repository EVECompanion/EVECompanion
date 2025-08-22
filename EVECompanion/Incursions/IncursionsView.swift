//
//  IncursionsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import SwiftUI
import EVECompanionKit

struct IncursionsView: View {
    
    @StateObject private var incursionManager: ECKIncursionManager = .init()
    
    var body: some View {
        Group {
            switch incursionManager.loadingState {
            case .ready,
                 .reloading:
                List(incursionManager.incursions, rowContent: { incursion in
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            ECImage(id: incursion.faction.factionId,
                                    category: .corporation)
                                .frame(width: 60, height: 60)
                            
                            VStack(alignment: .leading) {
                                Text(incursion.faction.name)
                                    .font(.title2)
                                Text("\(incursion.state.localized): \(incursion.stagingSolarSystem.solarSystemName)")
                                Text("\(incursion.constellation.name), \(incursion.stagingSolarSystem.region.name)")
                            }
                        }
                        
                        Text("System Control: \(Int(incursion.influence * 100))%")
                        ProgressView(value: incursion.influence, total: 1.0)
                            
                    }
                })
                .refreshable {
                    await incursionManager.loadIncursions()
                }
                
            case .loading:
                ProgressView()
                
            case .error:
                RetryButton {
                    await incursionManager.loadIncursions()
                }
                
            }
        }
        .onAppear(perform: {
            Task {
                await incursionManager.loadIncursions()
            }
        })
        .navigationTitle("Incursions")
    }
    
}

#Preview {
    NavigationStack {
        IncursionsView()
    }
}
