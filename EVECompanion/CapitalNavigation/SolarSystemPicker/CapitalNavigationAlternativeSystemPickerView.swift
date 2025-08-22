//
//  CapitalNavigationAlternativeSystemPickerView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 12.03.25.
//

import SwiftUI
import EVECompanionKit

struct CapitalNavigationAlternativeSystemPickerView: View {
    
    private let manager: ECKCapitalNavigationManager
    private let previousSystem: ECKSolarSystem
    private let systemToReplace: ECKSolarSystem
    private let nextSystem: ECKSolarSystem
    private let jumpRange: Double
    private let pickedSystem: (ECKSolarSystem) -> Void
    @State private var alternativeSystems: [ECKSolarSystem]?
    @Environment(\.dismiss) private var dismiss
    
    init(manager: ECKCapitalNavigationManager,
         previousSystem: ECKSolarSystem,
         systemToReplace: ECKSolarSystem,
         nextSystem: ECKSolarSystem,
         jumpRange: Double, 
         pickedSystem: @escaping (ECKSolarSystem) -> Void) {
        self.manager = manager
        self.previousSystem = previousSystem
        self.systemToReplace = systemToReplace
        self.nextSystem = nextSystem
        self.jumpRange = jumpRange
        self.pickedSystem = pickedSystem
    }
    
    var body: some View {
        NavigationStack {
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
            .navigationTitle("Alternative for \(systemToReplace.solarSystemName)")
            .task {
                loadData()
            }
        }
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
    
    private func loadData() {
        Task { @MainActor in
            self.alternativeSystems = await manager.alternativeSystems(previousSystem: previousSystem,
                                                                       systemToReplace: systemToReplace,
                                                                       nextSystem: nextSystem,
                                                                       jumpRange: jumpRange)
        }
    }
    
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CapitalNavigationAlternativeSystemPickerView(manager: .init(),
                                                         previousSystem: .init(solarSystemId: 30003135),
                                                         systemToReplace: .init(solarSystemId: 30003105),
                                                         nextSystem: .init(solarSystemId: 30001839),
                                                         jumpRange: 10) { _ in
                return
            }
        }
}
