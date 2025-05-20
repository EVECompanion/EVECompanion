//
//  CoordinatorView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 11.04.25.
//

import SwiftUI

struct CoordinatorView: View {
    
    @StateObject private var coordinator: Coordinator
    
    init(initialScreen: AppScreen) {
        self._coordinator = .init(wrappedValue: Coordinator(initialScreen: initialScreen))
    }
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.createView(for: coordinator.initialScreen)
                .navigationDestination(for: AppScreen.self) { screen in
                    coordinator.createView(for: screen)
                }
        }
        .environmentObject(coordinator)
    }
    
}
