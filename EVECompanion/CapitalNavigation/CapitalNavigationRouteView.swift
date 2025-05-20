//
//  CapitalNavigationRouteView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 13.03.25.
//

import SwiftUI
import EVECompanionKit

struct CapitalNavigationRouteView: View {
    
    @ObservedObject var manager: ECKCapitalNavigationManager
    @Binding var alternativeSystemPickerData: CapitalNavigationView.AlternativeSystemDataContainer?
    
    var body: some View {
        Section {
            if manager.isRouteLoading {
                ProgressView()
            } else {
                if let route = manager.route {
                    if let systems = route.route {
                        ForEach(Array(systems.enumerated()), id: \.element.id) { entry in
                            if entry.offset > 0 {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Image(systemName: "point.topleft.down.to.point.bottomright.filled.curvepath")
                                            .resizable()
                                            .frame(maxWidth: 20, maxHeight: 20)
                                            .padding(.horizontal, 10)
                                        
                                        Text("\(ECFormatters.jumpDistance(entry.element.system.distance(to: systems[entry.offset - 1].system) / CCP_LY_FACTOR)) Lightyears")
                                    }
                                    
                                    HStack {
                                        Image(systemName: "fuelpump")
                                            .resizable()
                                            .frame(maxWidth: 20, maxHeight: 20)
                                            .padding(.horizontal, 10)
                                        
                                        Text("\(ECFormatters.fuelConsumption(route.fuelConsumption(from: systems[entry.offset - 1], to: entry.element))) Isotopes")
                                    }
                                }
                            }
                            
                            VStack(spacing: 20) {
                                SolarSystemCell(system: entry.element.system)
                                
                                solarSystemButton(system: entry.element,
                                                  offset: entry.offset,
                                                  route: systems)
                            }
                            
                        }
                    } else {
                        Text("Routing not possible.")
                    }
                } else {
                    Text("Select at least two destinations.")
                }
            }
        } header: {
            Text("Route")
        } footer: {
            if let totalDistance = manager.route?.totalDistance,
               let fuelConsumption = manager.route?.totalFuelConsumption,
               manager.isRouteLoading == false {
                VStack(alignment: .leading) {
                    Text("Total Distance: \(ECFormatters.jumpDistance(totalDistance / CCP_LY_FACTOR)) lightyears")
                    
                    Text("Estimated Fuel Consumption: \(fuelConsumption) Isotopes")
                }
            }
        }
    }
    
    @ViewBuilder
    private func solarSystemButton(system: ECKCapitalJumpRoute.SystemEntry, offset: Int, route: [ECKCapitalJumpRoute.SystemEntry]) -> some View {
        if offset > 0 && offset < route.count - 1 {
            Button {
                alternativeSystemPickerData = .init(previousSystem: route[offset - 1].system,
                                                    system: system,
                                                    nextSystem: route[offset + 1].system,
                                                    jumpRange: manager.jumpRange ?? 0)
            } label: {
                Text("Pick Alternative")
            }
        }
    }
    
}

#Preview {
    Form {
        CapitalNavigationRouteView(manager: .init(route: .dummy1),
                                   alternativeSystemPickerData: .constant(nil))
    }
}
