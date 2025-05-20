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
    let target: CapitalNavigationView.NewSolarSystemTarget
    let pickedSystem: (ECKSolarSystem) -> Void
    @State var searchText: String = ""
    @State var systems: [ECKSolarSystem] = []
    @Environment(\.dismiss) var dismiss
    @State var searchHistory: [ECKSolarSystem] = {
        let systemIds = UserDefaults.standard.array(forKey: Self.searchHistoryDefaultsKey) as? [Int] ?? []
        return systemIds.map({ .init(solarSystemId: $0) })
    }()
    
    var body: some View {
        NavigationStack {
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
            .navigationTitle(target.systemPickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty == false {
                    systems = ECKSDEManager.shared.searchCapitalJumpDestinationSystems(newValue)
                } else {
                    systems = []
                }
            }
        }
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
            CapitalNavigationSolarSystemPickerView(target: .destination) { _ in
                return
            }
        }
}
