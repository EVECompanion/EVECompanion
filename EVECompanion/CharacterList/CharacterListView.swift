//
//  CharacterListView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 08.05.24.
//

import SwiftUI
import AuthenticationServices
import EVECompanionKit

struct CharacterListView: View {
    
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @EnvironmentObject var notificationManager: ECKNotificationManager
    @Environment(\.characterStorage) private var characterStorage
    @Environment(\.scenePhase) var scenePhase
    @Binding var selectedCharacter: CharacterSelection
    
    init(selectedCharacter: Binding<CharacterSelection>) {
        self._selectedCharacter = selectedCharacter
    }
    
    let skillTimer = Timer.publish(every: 1,
                                   on: .main,
                                   in: .common).autoconnect()
    
    @AppStorage(ECKDefaultKeys.didDismissPushCTA.rawValue) private var didDismissPushCTA: Bool = false
    
    var body: some View {
        List {
            if let didGrantPushPermission = notificationManager.didGrantPermission,
               didGrantPushPermission == false,
               didDismissPushCTA == false,
               characterStorage.characters.isEmpty == false,
               UserDefaults.standard.isDemoModeEnabled == false {
                Section {
                    PushPermissionCTA()
                }
            }
            
            ForEach(characterStorage.characters) { character in
                CharacterCell(character: character,
                              selectedCharacter: $selectedCharacter)
            }
            
        }
        .animation(.spring, value: notificationManager.didGrantPermission)
        .animation(.spring, value: didDismissPushCTA)
        .refreshable {
            await characterStorage.reloadCharacters()
        }
        .navigationTitle("Characters")
        .toolbar(content: {
            ToolbarItem {
                Button(action: {
                    if UserDefaults.standard.isDemoModeEnabled && characterStorage.characters.isEmpty == false {
                        return
                    }
                    
                    Task {
                        try? await ECKAuthenticationSession.start(authenticationHandler: { url, scheme in
                            return try await webAuthenticationSession.authenticate(using: url, callbackURLScheme: scheme)
                        })
                    }
                    
                }, label: {
                    Text("Add Character")
                })
            }
        })
        .onReceive(skillTimer, perform: { _ in
            characterStorage.characters.forEach({ $0.objectWillChange.send() })
        })
        .onAppear {
            selectedCharacter = .empty
            characterStorage.triggerAutomaticReloadIfNecessary()
        }
    }
    
}

#Preview {
    NavigationStack {
        CharacterListView(selectedCharacter: .constant(.empty))
            .environment(\.characterStorage, .init(preview: true))
    }
}
