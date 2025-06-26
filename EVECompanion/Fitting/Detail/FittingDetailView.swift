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
    private let character: ECKCharacter
    
    init(character: ECKCharacter, fitting: ECKCharacterFitting) {
        self.character = character
        self.fitting = fitting
    }
    
    var body: some View {
        VStack {
            FittingStatsView(fitting: fitting)
            
            Picker("", selection: $selectedTab) {
                Text("Info").tag(FittingDetailTab.info)
                Text("Modules").tag(FittingDetailTab.modules)
                Text("Drones").tag(FittingDetailTab.drones)
//                Text("Implants").tag(FittingDetailTab.implants)
//                Text("Cargo").tag(FittingDetailTab.cargo)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 10)

            TabView(selection: $selectedTab) {
                FittingDetailInfoView(character: character, fitting: fitting)
                    .tag(FittingDetailTab.info)
                
                FittingDetailModulesView(character: character, fitting: fitting)
                    .tag(FittingDetailTab.modules)
                
                FittingDetailDronesView(character: character, fitting: fitting)
                    .tag(FittingDetailTab.drones)
                
            }
            .animation(.spring, value: selectedTab)
        }
        .tabViewStyle(.page)
        .task {
            fitting.calculateAttributes(skills: character.skills ?? .empty)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(fitting.name)
    }
    
}

#Preview {
    CoordinatorView(initialScreen: .fittingDetail(.dummy, .dummyAvatar))
}
