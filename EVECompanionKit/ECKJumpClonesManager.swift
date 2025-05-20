//
//  ECKJumpClonesManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.06.24.
//

public import Combine

public class ECKJumpClonesManager: ObservableObject {
    
    public let character: ECKCharacter
    let isPreview: Bool
    
    @Published public var loadingState: ECKLoadingState = .loading
    @Published public var jumpClones: ECKJumpClones?
    
    public init(character: ECKCharacter, isPreview: Bool = false) {
        self.character = character
        self.isPreview = isPreview
        Task {
            await loadJumpClones()
        }
    }
    
    @MainActor
    public func loadJumpClones() async {
        guard UserDefaults.standard.isDemoModeEnabled == false && isPreview == false else {
            self.jumpClones = .dummy
            self.loadingState = .ready
            return
        }
        
        if jumpClones == nil {
            loadingState = .loading
        } else {
            loadingState = .reloading
        }
        
        let resource = ECKJumpClonesResource(token: character.token)
        do {
            self.jumpClones = try await ECKWebService().loadResource(resource: resource).response
            loadingState = .ready
        } catch {
            logger.error("Error while fetching jump clones \(error)")
            loadingState = .error
        }
    }
    
}
