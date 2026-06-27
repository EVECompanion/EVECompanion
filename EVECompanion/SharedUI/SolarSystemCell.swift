//
//  SolarSystemCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 12.03.25.
//

import SwiftUI
import EVECompanionKit

struct SolarSystemCell: View {
    
    @ObservedObject var system: ECKSolarSystem
    
    var body: some View {
        HStack {
            Group {
                if let imageSource = system.primaryImageSource {
                    ECImage(id: imageSource.id, category: imageSource.category)
                }
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(system.solarSystemName)
                        .font(.title2)
                    
                    Spacer()
                    
                    Text(ECFormatters.securityStatus(Float(system.security)))
                        .foregroundStyle(securityLabelColor)
                }
                
                if let sovereigntyName = system.sovereignty?.displayName {
                    Text(sovereigntyName)
                        .font(.title3)
                }
                
                Text(system.region.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.spring, value: system.sovereignty)
        .animation(.spring, value: system.sovereignty?.alliance)
    }
    
    private var securityLabelColor: Color {
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

#Preview {
    List {
        SolarSystemCell(system: .init(solarSystemId: 30000142))
        SolarSystemCell(system: .init(solarSystemId: 30003135))
        SolarSystemCell(system: .init(solarSystemId: 30045332))
        SolarSystemCell(system: .init(solarSystemId: 31001338))
    }
}
