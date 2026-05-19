//
//  MapView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 19.05.26.
//

import SwiftUI
import EVECompanionKit

struct MapView: View {
    
    @State private var systems: [ECKSolarSystem] = []
    
    var body: some View {
        VStack {
            Text("Map goes here.")
            Text("Systems loaded: \(systems.count)")
        }
        .task {
            systems = ECKSDEManager.shared.getAllSolarSystems()
        }
    }
    
}
