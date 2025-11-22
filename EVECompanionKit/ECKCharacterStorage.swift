//
//  ECKCharacterStorage.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.05.24.
//

import Foundation
import SwiftUI
public import Combine
#if DEBUG
import Pulse
#endif
import WidgetKit

public class ECKCharacterStorage: ObservableObject {
    
    @Published public var characters: [ECKCharacter] = []
    
    private var subscriptions = Set<AnyCancellable>()
    
    private var lastReloadDate: Date?
    private let automaticReloadInterval: TimeInterval = .fromHours(hours: 1)
    
    @MainActor
    var currentNotificationSchedulingTask: Task<Void, Never>?
    
    public init(preview: Bool = false) {
        guard preview == false else {
            self.characters = [.dummy]
            return
        }
        
        #if DEBUG
        Experimental.swizzleURLSession()
        #endif
        
        UserDefaults.standard
            .publisher(for: \.isDemoModeEnabled)
            .removeDuplicates()
            .sink { [weak self] isDemoModeEnabled in
                guard let self else {
                    return
                }
                
                Task { @MainActor in
                    await self.setup(isDemoModeEnabled: isDemoModeEnabled)
                }
            }
            .store(in: &subscriptions)
        
        NotificationCenter
            .default
            .publisher(for: .tokensDidChange)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                
                Task { @MainActor in
                    await self.reloadCharacters()
                }
            }
            .store(in: &subscriptions)
        
        NotificationCenter
            .default
            .publisher(for: .sdeUpdated)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                
                Task { @MainActor in
                    await self.reloadCharacters()
                }
            }
            .store(in: &subscriptions)
        
        NotificationCenter
            .default
            .publisher(for: .pushPermissionGranted)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                
                Task {
                    await self.reloadNotifications()
                }
            }
            .store(in: &subscriptions)
        
        UserDefaults
            .standard
            .publisher(for: \.enableEmptySkillQueueNotifications, options: .new)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task {
                    await self?.reloadNotifications()
                }
            }
            .store(in: &subscriptions)
        
        UserDefaults
            .standard
            .publisher(for: \.enableSkillCompletedNotifications, options: .new)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task {
                    await self?.reloadNotifications()
                }
            }
            .store(in: &subscriptions)
    }
    
    private func setup(isDemoModeEnabled: Bool) async {
        if isDemoModeEnabled {
            await setupDemoMode()
        } else {
            await setupNormalMode()
        }
    }
    
    @MainActor
    private func setupDemoMode() async {
        self.characters = []
    }
    
    private func setupNormalMode() async {
        await reloadCharactersNormalMode()
    }
    
    public func reloadCharacters() async {
        if UserDefaults.standard.isDemoModeEnabled {
            await reloadCharactersDemoMode()
        } else {
            await reloadCharactersNormalMode()
        }
    }
    
    @MainActor
    private func reloadCharactersDemoMode() async {
        if self.characters == [.dummy] {
            self.characters = []
        } else {
            self.characters = [.dummy]
        }
        
        self.objectWillChange.send()
    }
    
    @MainActor
    public func triggerAutomaticReloadIfNecessary() {
        Task { @MainActor in
            guard UserDefaults.standard.isDemoModeEnabled == false else {
                return
            }
            
            guard let lastReloadDate else {
                return
            }
            
            if lastReloadDate + automaticReloadInterval < Date() {
                logger.info("Triggering automatic reload.")
                await reloadCharacters()
            }
        }
    }
    
    @MainActor
    private func reloadCharactersNormalMode() async {
        lastReloadDate = .init()
        let tokens = ECKKeychain.getTokens(target: .character)
        characters = tokens.map({ .init(token: $0, dataLoadingTarget: .character) })
        await reloadNotifications()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    @MainActor
    private func reloadNotifications() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            logger.info("Skipping notification reloading, running in demo mode.")
            return
        }
        
        if let currentNotificationSchedulingTask {
            await currentNotificationSchedulingTask.value
        }
        
        currentNotificationSchedulingTask = Task { @MainActor in
            guard ECKSDEManager.shared.connection != nil else {
                logger.warning("Skipping Notification scheduling, no SDE connection available.")
                return
            }
            
            let charactersWithValidLogins = characters.filter({ $0.hasValidToken })
            
            for character in charactersWithValidLogins {
                _ = await character.initialDataLoadingTask?.value
                
                if character.skillqueue == nil {
                    logger.warning("Character \(character.name) skillqueue is not set, reloading it now.")
                    let skillqueueResource = ECKCharacterSkillqueueResource(token: character.token)
                    let skillqueueResponse = try? await ECKWebService().loadResource(resource: skillqueueResource).response
                    character.skillqueue = skillqueueResponse
                }
                
                guard character.hasValidToken else {
                    /// If the login of this character is now expired
                    /// (it was not previously because we filtered the
                    /// characters by token validity), just ignore it.
                    /// Before giving the character list to the NotificationManager
                    /// we do a final filter by token validity.
                    continue
                }
                
                guard character.skillqueue != nil else {
                    logger.error("Character \(character.name) skillqueue is not set.")
                    return
                }
            }
            
            await ECKNotificationManager.shared.scheduleNotifications(for: characters.filter({ $0.hasValidToken }))
            
            logger.info("Finished scheduling new notifications.")
        }
    }
    
    public func performAppRefreshTask() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            logger.info("Skipping app data reloading, running in demo mode.")
            return
        }
        
        await withTaskGroup { taskGroup in
            for character in characters {
                taskGroup.addTask {
                    await character.reloadWidgetData()
                }
            }
        }
        
        WidgetCenter.shared.reloadAllTimelines()
        
        await reloadNotifications()
        await currentNotificationSchedulingTask?.value
    }
    
}
