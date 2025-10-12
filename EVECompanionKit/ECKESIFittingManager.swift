//
//  ECKESIFittingManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 30.09.25.
//

import Foundation

public class ECKESIFittingManager: ObservableObject {
    
    public let character: ECKCharacter
    private let isPreview: Bool
    
    @Published public var esiLoadingState: ECKLoadingState = .loading
    @Published var loadedESIFittings: [ECKCharacterFitting] = []
    public var esiFittings: [ECKCharacterFitting] {
        if searchText.isEmpty == false {
            return loadedESIFittings.filter { fitting in
                return fitting.name.lowercased().contains(searchText.lowercased())
                || fitting.ship.item.name.lowercased().contains(searchText.lowercased())
            }
        } else {
            return loadedESIFittings
        }
    }
    
    @Published public var searchText: String = ""
    
    public init(character: ECKCharacter, isPreview: Bool = false) {
        self.character = character
        self.isPreview = isPreview
        Task {
            await loadFittings()
        }
    }
    
    @MainActor
    public func loadFittings() async {
        guard UserDefaults.standard.isDemoModeEnabled == false && isPreview == false else {
            self.loadedESIFittings = [
                .dummyAvatar
            ]
            self.esiLoadingState = .ready
            return
        }
        
        if loadedESIFittings.isEmpty {
            esiLoadingState = .loading
        } else {
            esiLoadingState = .reloading
        }
        
        let resource = ECKCharacterFittingsResource(token: character.token)
        do {
            let esiFittings = try await ECKWebService().loadResource(resource: resource).response
            self.loadedESIFittings = esiFittings.map({ fitting in
                return .init(fitting: fitting)
            })
            .sorted(by: { lhs, rhs in
                return lhs.ship.item.name < rhs.ship.item.name
            })
            esiLoadingState = .ready
        } catch {
            logger.error("Error while fetching character fittings \(error)")
            esiLoadingState = .error
        }
    }
    
}
