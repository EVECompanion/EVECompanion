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
    private let manager: ECKFittingManager
    
    private var character: ECKCharacter {
        return manager.character
    }
    
    private var canUseDrones: Bool {
        return fitting.maxDroneCapacity ?? 0 > 0
    }
    
    init(manager: ECKFittingManager, fitting: ECKCharacterFitting) {
        self.manager = manager
        self.fitting = fitting
    }
    
    var body: some View {
        VStack {
            FittingStatsView(fitting: fitting)
            
            Picker("", selection: $selectedTab) {
                Text("Info").tag(FittingDetailTab.info)
                Text("Modules").tag(FittingDetailTab.modules)
                if canUseDrones {
                    Text("Drones").tag(FittingDetailTab.drones)
                }
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
                
                if canUseDrones {
                    FittingDetailDronesView(character: character, fitting: fitting)
                        .tag(FittingDetailTab.drones)
                }
                
            }
            .background(Color(uiColor: UIColor.secondarySystemBackground))
            .animation(.spring, value: selectedTab)
            .animation(.spring, value: canUseDrones)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .task {
            fitting.calculateAttributes(skills: character.skills ?? .empty)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(fitting.name)
    }
    
}

#Preview {
    CoordinatorView(initialScreen: .fittingDetail(.init(character: .dummy, isPreview: true), .dummyAvatar))
}
