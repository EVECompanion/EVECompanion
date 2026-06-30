//
//  CapitalNavigationSolarSystemPickerView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 12.03.25.
//

import SwiftUI
import EVECompanionKit

struct CapitalNavigationSolarSystemPickerView: View {
    
    private static let searchHistoryDefaultsKey = "CapitalNavigation.SolarSystem.SearchHistory"
    private enum PickerMode: Hashable {
        case list
        case map
    }

    let target: CapitalNavigationView.NewSolarSystemTarget
    @ObservedObject private var manager: ECKCapitalNavigationManager
    private let mapOriginSystem: ECKSolarSystem?
    private let jumpRange: Double?
    private let routeSystems: [ECKSolarSystem]
    let pickedSystem: (ECKSolarSystem) -> Void
    @State var searchText: String = ""
    @State var systems: [ECKSolarSystem] = []
    @State private var pickerMode: PickerMode = .list
    @State private var mapSystems: [ECKSolarSystem]?
    @State private var isLoadingMapSystems: Bool = false
    @Environment(\.dismiss) var dismiss
    @State var searchHistory: [ECKSolarSystem] = {
        let systemIds = UserDefaults.standard.array(forKey: Self.searchHistoryDefaultsKey) as? [Int] ?? []
        return systemIds.map({ .init(solarSystemId: $0) })
    }()

    init(target: CapitalNavigationView.NewSolarSystemTarget,
         manager: ECKCapitalNavigationManager,
         mapOriginSystem: ECKSolarSystem?,
         jumpRange: Double?,
         routeSystems: [ECKSolarSystem],
         pickedSystem: @escaping (ECKSolarSystem) -> Void) {
        self.target = target
        self._manager = ObservedObject(wrappedValue: manager)
        self.mapOriginSystem = mapOriginSystem
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
            .navigationTitle(target.systemPickerTitle)
            .toolbar {
                if target == .destination {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            togglePickerMode()
                        } label: {
                            Image(systemName: pickerMode == .map ? "list.bullet" : "map")
                        }
                        .disabled(canShowMap == false)
                    }
                }
            }
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty == false {
                    systems = ECKSDEManager.shared.searchCapitalJumpDestinationSystems(newValue)
                } else {
                    systems = []
                }
            }
            .task(id: pickerMode) {
                guard pickerMode == .map else {
                    return
                }

                await loadMapSystemsIfNeeded()
            }
        }
    }

    private var canShowMap: Bool {
        target == .destination && mapOriginSystem != nil && jumpRange != nil
    }

    private var listContent: some View {
        List {
            if systems.isEmpty == false {
                ForEach(systems) { system in
                    solarSystemButton(system: system)
                }
            } else if searchHistory.isEmpty == false {
                Section("Search History") {
                    ForEach(searchHistory) { system in
                        solarSystemButton(system: system)
                    }
                }
            }
        }
        .searchable(text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Solar System")
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
        guard let mapSystems,
              let mapOriginSystem else {
            return nil
        }

        let selectableSystemIds = Set(mapSystems.map(\.id))
        return MapSystemSelectionConfiguration(selectableSystemIds: selectableSystemIds,
                                               highlightedSystemIds: selectableSystemIds,
                                               jumpRouteSystemIds: routeSystems.map(\.id),
                                               initialFocusSystem: mapOriginSystem) { system in
            addToSearchHistory(system: system)
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
            addToSearchHistory(system: system)
            pickedSystem(system)
            dismiss()
        } label: {
            SolarSystemCell(system: system)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func loadMapSystemsIfNeeded() async {
        guard mapSystems == nil,
              isLoadingMapSystems == false,
              let mapOriginSystem,
              let jumpRange else {
            return
        }

        isLoadingMapSystems = true
        mapSystems = await manager.systemsInRange(from: mapOriginSystem,
                                                  jumpRange: jumpRange)
        isLoadingMapSystems = false
    }
    
    private func addToSearchHistory(system: ECKSolarSystem) {
        var searchHistory = self.searchHistory
        searchHistory.removeAll { $0.id == system.id }
        searchHistory.insert(system, at: 0)
        UserDefaults.standard.set(searchHistory.map(\.self.id), forKey: Self.searchHistoryDefaultsKey)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CapitalNavigationSolarSystemPickerView(target: .destination,
                                                   manager: .init(),
                                                   mapOriginSystem: .init(solarSystemId: 30000142),
                                                   jumpRange: 10,
                                                   routeSystems: []) { _ in
                return
            }
        }
}
