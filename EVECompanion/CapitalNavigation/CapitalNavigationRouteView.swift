//
//  CapitalNavigationRouteView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 13.03.25.
//

import SwiftUI
import EVECompanionKit

struct CapitalNavigationRouteView: View {

    private enum RouteDisplayMode: Hashable {
        case list
        case map
    }
    
    @ObservedObject var manager: ECKCapitalNavigationManager
    @Binding var alternativeSystemPickerData: CapitalNavigationView.AlternativeSystemDataContainer?
    @State private var routeDisplayMode: RouteDisplayMode = .list
    
    var body: some View {
        Section {
            if manager.isRouteLoading {
                ProgressView()
            } else {
                if let route = manager.route {
                    if let systems = route.route {
                        switch routeDisplayMode {
                        case .list:
                            routeListContent(route: route, systems: systems)
                        case .map:
                            routeMapContent(systems: systems)
                        }
                    } else {
                        Text("Routing not possible.")
                    }
                } else {
                    Text("Select at least two destinations.")
                }
            }
        } header: {
            HStack {
                Text("Route")

                Spacer()

                if canShowRouteMap {
                    Button {
                        toggleRouteDisplayMode()
                    } label: {
                        Image(systemName: routeDisplayMode == .map ? "list.bullet" : "map")
                    }
                    .accessibilityLabel(routeDisplayMode == .map ? "Show route list" : "Show route map")
                }
            }
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

    private var canShowRouteMap: Bool {
        guard let systems = manager.route?.route else {
            return false
        }

        return ECKCapitalJumpMapOverlay.staticRoutePresentation(systemIds: systems.map(\.system.id)) != nil
    }

    @ViewBuilder
    private func routeListContent(route: ECKCapitalJumpRoute, systems: [ECKCapitalJumpRoute.SystemEntry]) -> some View {
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
    }

    @ViewBuilder
    private func routeMapContent(systems: [ECKCapitalJumpRoute.SystemEntry]) -> some View {
        if let configuration = routeMapConfiguration(systems: systems) {
            MapView(selectionConfiguration: configuration,
                    showsControls: false,
                    showsCharacterMarkers: false)
                .frame(maxWidth: .infinity, minHeight: 420, maxHeight: 420)
                .clipped()
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        } else {
            Text("Routing not possible.")
        }
    }

    private func routeMapConfiguration(systems: [ECKCapitalJumpRoute.SystemEntry]) -> MapSystemSelectionConfiguration? {
        let systemsById = Dictionary(uniqueKeysWithValues: systems.map { ($0.system.id, $0.system) })
        guard let presentation = ECKCapitalJumpMapOverlay.staticRoutePresentation(systemIds: systems.map(\.system.id)) else {
            return nil
        }

        return MapSystemSelectionConfiguration(selectableSystemIds: presentation.selectableSystemIds,
                                               highlightedSystemIds: presentation.highlightedSystemIds,
                                               jumpRouteSystemIds: presentation.jumpRouteSystemIds,
                                               initialFocusSystem: presentation.initialFocusSystemId.flatMap { systemsById[$0] }) { _ in
            return
        }
    }

    private func toggleRouteDisplayMode() {
        routeDisplayMode = routeDisplayMode == .map ? .list : .map
    }
    
    @ViewBuilder
    private func solarSystemButton(system: ECKCapitalJumpRoute.SystemEntry, offset: Int, route: [ECKCapitalJumpRoute.SystemEntry]) -> some View {
        if offset > 0 && offset < route.count - 1 {
            Button {
                alternativeSystemPickerData = .init(previousSystem: route[offset - 1].system,
                                                    system: system,
                                                    nextSystem: route[offset + 1].system,
                                                    jumpRange: manager.jumpRange ?? 0,
                                                    routeSystems: route.map(\.system))
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
