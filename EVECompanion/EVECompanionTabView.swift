//
//  EVECompanionTabView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 15.05.24.
//

import SwiftUI
import EVECompanionKit

struct EVECompanionTabView: View {
    
    @StateObject var sdeUpdater = ECKSDEUpdater()
    @Binding var selectedCharacter: CharacterSelection
    @AppStorage(ECKDefaultKeys.showCorpTab.rawValue) private var showCorpTab: Bool = true
    
    init(selectedCharacter: Binding<CharacterSelection>) {
        self._selectedCharacter = selectedCharacter
    }
    
    var body: some View {
        TabView {
            CoordinatorView(initialScreen: .characterList($selectedCharacter))
                .tabItem {
                    Label("Characters", systemImage: "person.3")
                }
            
            if showCorpTab {
                CoordinatorView(initialScreen: .corporationList)
                    .tabItem {
                        Label("Corporations", systemImage: "briefcase")
                    }
            }
            
            CapitalNavigationTabView()
                .tabItem {
                    Label("Navigation", systemImage: "point.topright.arrow.triangle.backward.to.point.bottomleft.filled.scurvepath")
                }
            
            CoordinatorView(initialScreen: .universe)
                .tabItem {
                    Label("Universe", systemImage: "moon.stars")
                }
            
            CoordinatorView(initialScreen: .settings)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .animation(.spring, value: showCorpTab)
        .sheet(isPresented: .init(get: {
            sdeUpdater.state != .noUpdateAvailable
        }, set: { _ in
            sdeUpdater.confirmUpdate()
        }), content: {
            switch sdeUpdater.state {
            
            case .noUpdateAvailable:
                EmptyView()
                
            case .downloadRequired:
                SDEUpdateView(mode: .required, 
                              sdeUpdater: sdeUpdater)
                
            case .updateAvailable:
                SDEUpdateView(mode: .update,
                              sdeUpdater: sdeUpdater)
                
            }
        })
        .onAppear(perform: {
            Task {
                await sdeUpdater.checkForUpdate()
            }
        })
    }
    
}

#Preview {
    EVECompanionTabView(selectedCharacter: .constant(.empty))
        .environment(\.characterStorage, .init(preview: true))
}
