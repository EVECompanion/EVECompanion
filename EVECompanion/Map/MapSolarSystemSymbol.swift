//
//  MapSolarSystemSymbol.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 20.05.26.
//

import SwiftUI
import EVECompanionKit

struct MapSolarSystemSymbol: View {
    
    let system: ECKSolarSystem
    
    var body: some View {
        Text(system.solarSystemName)
            .padding()
            .frame(minWidth: 80)
            .background {
                Capsule()
                    .stroke()
                    .background {
                        ZStack {
                            Capsule().fill(Color(uiColor: .systemBackground))
                            Capsule().fill(fillColor.opacity(0.4))
                        }
                        
                    }
            }
    }
    
    private var fillColor: Color {
        if system.security >= 0.5 {
            // Highsec
            Color.blue
        } else if system.security >= 0.1 {
            Color.orange
        } else {
            Color.pink
        }
    }
    
}

#Preview("Jita") {
    MapSolarSystemSymbol(system: .init(solarSystemId: 30000142))
}

#Preview("Aunen") {
    MapSolarSystemSymbol(system: .init(solarSystemId: 30001398))
}

#Preview("4-HWWF") {
    MapSolarSystemSymbol(system: .init(solarSystemId: 30000240))
}
