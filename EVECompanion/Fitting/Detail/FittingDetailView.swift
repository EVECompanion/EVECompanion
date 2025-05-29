//
//  FittingDetailView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import SwiftUI
import EVECompanionKit

struct FittingDetailView: View {
    
    enum FittingDetailTab: Hashable {
        case info
        case modules
        case drones
        case implants
        case cargo
    }
    
    @ObservedObject var fitting: ECKCharacterFitting
    @State private var selectedTab: FittingDetailTab = .info
    
    init(fitting: ECKCharacterFitting) {
        self.fitting = fitting
    }
    
    var body: some View {
        VStack {
            Picker("", selection: $selectedTab) {
                Text("Info").tag(FittingDetailTab.info)
                Text("Modules").tag(FittingDetailTab.modules)
                Text("Drones").tag(FittingDetailTab.drones)
                Text("Implants").tag(FittingDetailTab.implants)
                Text("Cargo").tag(FittingDetailTab.cargo)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 10)

            TabView(selection: $selectedTab) {
                FittingDetailInfoView(fitting: fitting)
                    .tag(FittingDetailTab.info)
                
                Text("Module Stuff")
                    .tag(FittingDetailTab.modules)
                
            }
        }
        .tabViewStyle(.page)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(fitting.name)
    }
    
}

#Preview {
    CoordinatorView(initialScreen: .fittingDetail(.dummyAvatar))
}
