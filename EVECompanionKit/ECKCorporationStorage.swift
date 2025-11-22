//
//  ECKCorporationStorage.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 22.11.25.
//

import SwiftUI
public import Combine

public class ECKCorporationStorage: ObservableObject {
    
    @Published public private(set) var corporations: [ECKAuthenticatedCorporation] = []
    
    private var subscriptions = Set<AnyCancellable>()
    private var lastReloadDate: Date?
    private let automaticReloadInterval: TimeInterval = .fromHours(hours: 1)
    
    public init(preview: Bool = false) {
        guard preview == false else {
            self.corporations = [.dummy]
            return
        }
        
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
                    await self.reloadCorporations()
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
                    await self.reloadCorporations()
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
        self.corporations = []
    }
    
    private func setupNormalMode() async {
        await reloadCorporationsNormalMode()
    }
    
    public func reloadCorporations() async {
        if UserDefaults.standard.isDemoModeEnabled {
            await reloadCorporationsDemoMode()
        } else {
            await reloadCorporationsNormalMode()
        }
    }
    
    @MainActor
    private func reloadCorporationsDemoMode() async {
        if self.corporations == [.dummy] {
            self.corporations = []
        } else {
            self.corporations = [.dummy]
        }
        
        self.objectWillChange.send()
    }
    
    @MainActor
    private func reloadCorporationsNormalMode() async {
        lastReloadDate = .init()
        let tokens = ECKKeychain.getTokens(target: .corp)
        corporations = tokens.map({ .init(token: $0) })
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
                await reloadCorporations()
            }
        }
    }
    
}
