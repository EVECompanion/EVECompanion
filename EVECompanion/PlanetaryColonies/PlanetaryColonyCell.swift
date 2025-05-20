//
//  PlanetaryColonyCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 25.04.25.
//

import SwiftUI
import EVECompanionKit

struct PlanetaryColonyCell: View {
    
    let colony: ECKPlanetaryColonyManager.ECKColony
    
    var body: some View {
        NavigationLink(value: AppScreen.planetaryColony(colony)) {
            VStack(alignment: .leading) {
                HStack {
                    ECImage(id: colony.colony.planet.typeId,
                            category: .types)
                    .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading) {
                        Text(colony.colony.planet.name)
                            .font(.headline)
                        Text(colony.colony.planet.type.name)
                            .foregroundStyle(.secondary)
                    }
                }
                
                PlanetaryColonyWarningsView(warnings: colony.details.warnings)
            }
        }
    }
    
}

#Preview {
    NavigationStack {
        PlanetaryColoniesView(colonyManager: .init(character: .dummy,
                                                   isPreview: true))
    }
}
