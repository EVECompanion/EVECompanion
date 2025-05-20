//
//  CapitalNavigationTabView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 18.03.25.
//

import SwiftUI
import EVECompanionKit

struct CapitalNavigationTabView: View {
    
    @StateObject var manager = ECKCapitalRouteManager()
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        CapitalNavigationView()
                    } label: {
                        Label("Create new Route", image: "Icons/CapitalNavigation")
                    }
                }
                
                Section("Saved Routes") {
                    if let savedRoutes = manager.savedRoutes {
                        if savedRoutes.isEmpty {
                            Text("You did not save any routes.")
                        } else {
                            ForEach(savedRoutes) { route in
                                NavigationLink {
                                    CapitalNavigationView(navigationManager: .init(route: route))
                                } label: {
                                    CapitalJumpRouteCell(route: route)
                                }
                            }
                            .onDelete { indexSet in
                                manager.removeRoutes(indexSet)
                            }
                        }
                    } else {
                        ProgressView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Capital Navigation")
        }
        .environmentObject(manager)
    }
    
}

#Preview {
    CapitalNavigationTabView()
}
