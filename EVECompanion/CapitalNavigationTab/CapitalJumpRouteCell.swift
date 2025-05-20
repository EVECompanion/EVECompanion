//
//  CapitalJumpRouteCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 20.03.25.
//

import SwiftUI
import EVECompanionKit

struct CapitalJumpRouteCell: View {
    
    let route: ECKCapitalJumpRoute
    
    private var title: String {
        if let name = route.name {
            return name
        } else if route.destinationSystems.count >= 2 {
            let startSystem = route.destinationSystems.first!
            let destinationSystem = route.destinationSystems.last!
            
            return "\(startSystem.system.solarSystemName) to \(destinationSystem.system.solarSystemName)"
        } else {
            return "Route for \(route.ship.name)"
        }
    }
    
    var body: some View {
        HStack {
            ECImage(id: route.ship.typeId, category: .types)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title2)
                
                HStack {
                    Text(route.ship.name)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if let route = route.route {
                        Text("\(route.count - 1) Jumps")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .contentShape(Rectangle())
    }
    
}

#Preview {
    List {
        Section("Saved Routes") {
            CapitalJumpRouteCell(route: .dummy1)
            CapitalJumpRouteCell(route: .dummy2)
        }
    }
}
