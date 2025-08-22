//
//  PlanetaryColonyView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 21.04.25.
//

import SwiftUI
import EVECompanionKit

struct PlanetaryColonyView: View {
    
    let colony: ECKPlanetaryColonyManager.ECKColony
    
    var body: some View {
        List {
            ForEach(colony.details.pins, id: \.pinId) { pin in
                Section {
                    PlanetaryColonyPinView(pin: pin)
                }
            }
        }
        .navigationTitle(colony.colony.planet.name)
    }
    
}

#Preview {
    CoordinatorView(initialScreen: .planetaryColony(.init(colony: .dummy1,
                                                          details: .dummy1)))
}
