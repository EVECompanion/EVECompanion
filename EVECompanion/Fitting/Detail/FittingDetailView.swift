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
    @State private var showChangeNameAlert: Bool = false
    @State private var changeNameInput: String
    private let manager: ECKFittingManager
    
    private var character: ECKCharacter {
        return manager.character
    }
    
    init(manager: ECKFittingManager, fitting: ECKCharacterFitting) {
        self.manager = manager
        self.fitting = fitting
        self.changeNameInput = fitting.name
    }
    
    var body: some View {
        VStack {
            FittingStatsView(fitting: fitting)
            
            Picker("", selection: $selectedTab) {
                Text("Info").tag(FittingDetailTab.info)
                Text("Modules").tag(FittingDetailTab.modules)
                if fitting.canUseDrones {
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
                
                FittingDetailModulesView(character: character, fitting: fitting, manager: manager)
                    .tag(FittingDetailTab.modules)
                
                if fitting.canUseDrones {
                    FittingDetailDronesView(fittingManager: manager,
                                            fitting: fitting)
                        .tag(FittingDetailTab.drones)
                }
                
            }
            .background(Color(uiColor: UIColor.secondarySystemBackground))
            .animation(.spring, value: selectedTab)
            .animation(.spring, value: fitting.canUseDrones)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .task {
            await fitting.calculateAttributes(skills: character.skills ?? .empty)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(fitting.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showChangeNameAlert = true
                } label: {
                    Image(systemName: "rectangle.and.pencil.and.ellipsis")
                }
            }
        }
        .alert("Change name", isPresented: $showChangeNameAlert) {
            TextField("Fit Name", text: $changeNameInput)
            Button {
                fitting.setName(changeNameInput, manager: manager)
            } label: {
                Text("Ok")
            }
            
            Button(role: .cancel) {
                changeNameInput = fitting.name
            } label: {
                Text("Cancel")
            }
        }
    }
    
}

#Preview {
    CoordinatorView(initialScreen: .fittingDetail(.init(character: .dummy, isPreview: true), .dummyAvatar))
}
