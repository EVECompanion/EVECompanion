//
//  CapitalNavigationView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 10.03.25.
//

import SwiftUI
import EVECompanionKit

struct CapitalNavigationView: View {
    
    internal struct AlternativeSystemDataContainer: Identifiable {
        let id = UUID()
        let previousSystem: ECKSolarSystem
        let system: ECKCapitalJumpRoute.SystemEntry
        let nextSystem: ECKSolarSystem
        let jumpRange: Double
    }
    
    internal enum NewSolarSystemTarget {
        case destination
        case avoidance
        
        var buttonTitle: String {
            switch self {
            case .destination:
                "Add Destination System"
            case .avoidance:
                "Add System To Avoid"
            }
        }
        
        var systemPickerTitle: String {
            switch self {
            case .destination:
                return "Choose Capital Jump Destination"
            case .avoidance:
                return "Choose System To Avoid"
            }
        }
    }
    
    @StateObject var navigationManager: ECKCapitalNavigationManager = .init()
    @EnvironmentObject var routeManager: ECKCapitalRouteManager
    @State private var isSolarSystemPickerPresented: Bool = false
    @State private var isShipPickerPresented: Bool = false
    @State private var newSolarSystemTarget: NewSolarSystemTarget = .destination
    @State private var showsSaveAlert: Bool = false
    @State private var saveAlertTextInput: String = ""
    @State private var alternativeSystemPickerData: AlternativeSystemDataContainer?
    
    var body: some View {
        Form {
            CapitalNavigationInputView(manager: navigationManager,
                                       newSolarSystemTarget: $newSolarSystemTarget,
                                       isSolarSystemPickerPresented: $isSolarSystemPickerPresented,
                                       isShipPickerPresented: $isShipPickerPresented)
            CapitalNavigationRouteView(manager: navigationManager,
                                       alternativeSystemPickerData: $alternativeSystemPickerData)
        }
        .animation(.spring, value: navigationManager.selectedShip)
        .animation(.spring, value: navigationManager.selectedDestinationSystems)
        .animation(.spring, value: navigationManager.selectedAvoidanceSystems)
        .animation(.spring, value: navigationManager.isRouteLoading)
        .animation(.spring, value: navigationManager.route)
        .navigationTitle("Capital Navigation")
        .toolbar {
            ToolbarItem {
                Button("Save") {
                    showsSaveAlert = true
                }
                .disabled(navigationManager.route?.route == nil)
                .alert("Save Route", isPresented: $showsSaveAlert) {
                    TextField("Route Name", text: $saveAlertTextInput)
                    Button("Save", action: saveRoute)
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Name your route to make it easier to find again!")
                }
            }
        }
        .sheet(isPresented: $isSolarSystemPickerPresented) {
            CapitalNavigationSolarSystemPickerView(target: newSolarSystemTarget) { system in
                switch newSolarSystemTarget {
                case .avoidance:
                    navigationManager.selectedAvoidanceSystems.append(.init(system: system))
                case .destination:
                    navigationManager.selectedDestinationSystems.append(.init(system: system))
                }
            }
        }
        .sheet(isPresented: $isShipPickerPresented) {
            CapitalNavigationShipPickerView(manager: navigationManager) { ship in
                navigationManager.selectedShip = ship
            }
        }
        .sheet(item: $alternativeSystemPickerData) { data in
            CapitalNavigationAlternativeSystemPickerView(manager: navigationManager,
                                                         previousSystem: data.previousSystem,
                                                         systemToReplace: data.system.system,
                                                         nextSystem: data.nextSystem,
                                                         jumpRange: data.jumpRange) { pickedSystem in
                navigationManager.replaceRouteSystem(system: data.system, with: pickedSystem)
            }
        }
    }
    
    func saveRoute() {
        guard let route = navigationManager.route else {
            return
        }
        
        if saveAlertTextInput.isEmpty == false {
            route.name = saveAlertTextInput
        }
        
        routeManager.addRoute(route)
        saveAlertTextInput = ""
    }
    
}

#Preview {
    NavigationStack {
        CapitalNavigationView()
            .environmentObject(ECKCapitalRouteManager())
    }
}
