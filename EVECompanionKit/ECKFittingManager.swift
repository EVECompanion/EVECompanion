//
//  ECKFittingManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.25.
//

public import Combine

public class ECKFittingManager: ObservableObject {
    
    public let character: ECKCharacter
    private let isPreview: Bool
    
    @Published public var loadingState: ECKLoadingState = .loading
    public var fittings: [ECKCharacterFitting] {
        if searchText.isEmpty == false {
            return loadedFittings.filter { fitting in
                return fitting.name.lowercased().contains(searchText.lowercased())
                || fitting.ship.item.name.lowercased().contains(searchText.lowercased())
            }
        } else {
            return loadedFittings
        }
    }
    @Published public var searchText: String = ""
    
    @Published var loadedFittings: [ECKCharacterFitting] = []
    
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
            self.loadedFittings = [
                .dummyAvatar
            ]
            self.loadingState = .ready
            return
        }
        
        if fittings.isEmpty {
            loadingState = .loading
        } else {
            loadingState = .reloading
        }
        
        let resource = ECKCharacterFittingsResource(token: character.token)
        do {
            let esiFittings = try await ECKWebService().loadResource(resource: resource).response
            self.loadedFittings = esiFittings.map({ fitting in
                return .init(fitting: fitting)
            })
            loadingState = .ready
        } catch {
            logger.error("Error while fetching character fittings \(error)")
            loadingState = .error
        }
    }
    
}
