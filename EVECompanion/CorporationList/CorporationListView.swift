//
//  CorporationListView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 21.11.25.
//

import SwiftUI
import AuthenticationServices
import EVECompanionKit

struct CorporationListView: View {
    
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.corporationStorage) private var corporationStorage
    
    init() { }
    
    var body: some View {
        List {
            ForEach(corporationStorage.corporations) { corporation in
                AuthenticatedCorporationCell(corporation: corporation)
            }
        }
        .refreshable {
            await corporationStorage.reloadCorporations()
        }
        .navigationTitle("Corporations")
        .toolbar(content: {
            ToolbarItem {
                Button(action: {
                    if UserDefaults.standard.isDemoModeEnabled && corporationStorage.corporations.isEmpty == false {
                        return
                    }
                    
                    Task {
                        try? await ECKAuthenticationSession.start(target: .corp,
                                                                  authenticationHandler: { url, scheme in
                            return try await webAuthenticationSession.authenticate(using: url, callbackURLScheme: scheme)
                        })
                    }
                    
                }, label: {
                    Text("Add Corporation")
                })
            }
        })
        .onAppear {
            corporationStorage.triggerAutomaticReloadIfNecessary()
        }
    }
    
}

#Preview {
    NavigationStack {
        CorporationListView()
    }
}
