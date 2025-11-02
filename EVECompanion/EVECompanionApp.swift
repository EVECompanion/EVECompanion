//
//  EVECompanionApp.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 06.05.24.
//

import SwiftUI
import EVECompanionKit
import BackgroundTasks

@main
struct EVECompanionApp: App {
    
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    @StateObject var characterStorage: ECKCharacterStorage = .init()
    @StateObject var notificationManager: ECKNotificationManager = .shared
    @State var selectedCharacter: CharacterSelection = .empty
    @Environment(\.scenePhase) var scenePhase
    
    init() {
        // Initialize SDE immediately
        _ = ECKSDEManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            EVECompanionTabView(selectedCharacter: $selectedCharacter)
                .environment(\.characterStorage, characterStorage)
                .environment(\.selectedCharacter, selectedCharacter)
                .environmentObject(notificationManager)
                .onChange(of: scenePhase) { newPhase in
                    Task {
                        await notificationManager.refreshPermissionStatus()
                    }
                    
                    switch newPhase {
                    case .active:
                        characterStorage.triggerAutomaticReloadIfNecessary()
                    case .background:
                        ECKBackgroundTaskManager.shared.scheduleAppRefreshTask()
                    default:
                        break
                    }
                }
        }
        .backgroundTask(.appRefresh(ECKBackgroundTaskManager.TaskType.refreshTask.rawValue)) {
            logger.info("Invoked app refresh task.")
            await characterStorage.performAppRefreshTask()
            logger.info("Finished app refresh task.")
            ECKBackgroundTaskManager.shared.scheduleAppRefreshTask()
        }
    }
    
}
