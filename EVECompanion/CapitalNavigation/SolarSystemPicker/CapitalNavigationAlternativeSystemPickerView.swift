//
//  CapitalNavigationAlternativeSystemPickerView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 12.03.25.
//

import SwiftUI
import EVECompanionKit

struct CapitalNavigationAlternativeSystemPickerView: View {

    private enum PickerMode: Hashable {
        case list
        case map
    }
    
    private let manager: ECKCapitalNavigationManager
    private let previousSystem: ECKSolarSystem
    private let systemToReplace: ECKSolarSystem
    private let nextSystem: ECKSolarSystem
    private let jumpRange: Double
    private let routeSystems: [ECKSolarSystem]
    private let pickedSystem: (ECKSolarSystem) -> Void
    @State private var alternativeSystems: [ECKSolarSystem]?
    @State private var pickerMode: PickerMode = .list
    @Environment(\.dismiss) private var dismiss
    
    init(manager: ECKCapitalNavigationManager,
         previousSystem: ECKSolarSystem,
         systemToReplace: ECKSolarSystem,
         nextSystem: ECKSolarSystem,
         jumpRange: Double,
         routeSystems: [ECKSolarSystem],
         pickedSystem: @escaping (ECKSolarSystem) -> Void) {
        self.manager = manager
        self.previousSystem = previousSystem
        self.systemToReplace = systemToReplace
        self.nextSystem = nextSystem
        self.jumpRange = jumpRange
        self.routeSystems = routeSystems
        self.pickedSystem = pickedSystem
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch pickerMode {
                case .list:
                    listContent
                case .map:
                    mapContent
                }
            }
            .navigationTitle("Alternative for \(systemToReplace.solarSystemName)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        togglePickerMode()
                    } label: {
                        Image(systemName: pickerMode == .map ? "list.bullet" : "map")
                    }
                    .disabled((alternativeSystems ?? []).isEmpty)
                }
            }
            .task {
                await loadData()
            }
        }
    }

    private var listContent: some View {
        List {
            if let alternativeSystems {
                if alternativeSystems.isEmpty == false {
                    ForEach(alternativeSystems) { system in
                        solarSystemButton(system: system)
                    }
                } else {
                    Text("No alternative found.")
                }
            } else {
                ProgressView()
            }
        }
    }

    @ViewBuilder
    private var mapContent: some View {
        if let configuration = mapSelectionConfiguration {
            MapView(selectionConfiguration: configuration)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var mapSelectionConfiguration: MapSystemSelectionConfiguration? {
        guard let alternativeSystems,
              alternativeSystems.isEmpty == false else {
            return nil
        }

        let selectableSystemIds = Set(alternativeSystems.map(\.id))
        return MapSystemSelectionConfiguration(selectableSystemIds: selectableSystemIds,
                                               highlightedSystemIds: selectableSystemIds,
                                               replacementSystemId: systemToReplace.id,
                                               jumpRouteSystemIds: routeSystems.map(\.id),
                                               initialFocusSystem: previousSystem) { system in
            pickedSystem(system)
            dismiss()
        }
    }

    private func togglePickerMode() {
        pickerMode = pickerMode == .map ? .list : .map
    }
    
    @ViewBuilder
    private func solarSystemButton(system: ECKSolarSystem) -> some View {
        Button {
            pickedSystem(system)
            dismiss()
        } label: {
            SolarSystemCell(system: system)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func loadData() async {
        guard alternativeSystems == nil else {
            return
        }

        alternativeSystems = await manager.alternativeSystems(previousSystem: previousSystem,
                                                             systemToReplace: systemToReplace,
                                                             nextSystem: nextSystem,
                                                             jumpRange: jumpRange)
    }
    
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CapitalNavigationAlternativeSystemPickerView(manager: .init(),
                                                         previousSystem: .init(solarSystemId: 30003135),
                                                         systemToReplace: .init(solarSystemId: 30003105),
                                                         nextSystem: .init(solarSystemId: 30001839),
                                                         jumpRange: 10,
                                                         routeSystems: [
                                                            .init(solarSystemId: 30003135),
                                                            .init(solarSystemId: 30003105),
                                                            .init(solarSystemId: 30001839)
                                                         ]) { _ in
                return
            }
        }
}
