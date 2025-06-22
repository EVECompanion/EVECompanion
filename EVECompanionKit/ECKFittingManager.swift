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
    @Published public var fittings: [ECKCharacterFitting] = []
    
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
            self.fittings = [
                .init(description: "",
                      fittingId: 0,
                      items: [],
                      name: "Avatar",
                      ship: .init(typeId: 11567))
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
            self.fittings = try await ECKWebService().loadResource(resource: resource).response
            loadingState = .ready
        } catch {
            logger.error("Error while fetching character fittings \(error)")
            loadingState = .error
        }
    }
    
}
