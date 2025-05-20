//
//  ECKPlanetaryColonyManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.06.24.
//

public import Combine

public class ECKPlanetaryColonyManager: ObservableObject {
    
    public struct ECKColony: Identifiable {
        public var id: String { "\(colony.planet.id)" }
        
        public init(colony: ECKPlanetaryColony, details: ECKPlanetaryColonyDetails) {
            self.colony = colony
            self.details = details
        }
        
        public let colony: ECKPlanetaryColony
        public let details: ECKPlanetaryColonyDetails
    }
    
    @Published public var loadingState: ECKLoadingState = .loading
    @Published public var colonies: [ECKColony] = []
    
    public let character: ECKCharacter
    private let isPreview: Bool
    
    public init(character: ECKCharacter, isPreview: Bool = false) {
        self.character = character
        self.isPreview = isPreview
    }
    
    @MainActor
    public func loadColonies() async {
        guard isPreview == false && UserDefaults.standard.isDemoModeEnabled == false else {
            self.colonies = [.init(colony: .dummy1, details: .dummy1),
                             .init(colony: .dummy1, details: .dummy1)]
            self.loadingState = .ready
            return
        }
        
        if colonies.isEmpty {
            loadingState = .loading
        } else {
            loadingState = .reloading
        }
        
        do {
            let coloniesResource = ECKPlanetaryColoniesResource(token: character.token)
            let colonies = try await ECKWebService().loadResource(resource: coloniesResource).response
            
            self.colonies = try await withThrowingTaskGroup(of: ECKColony.self, returning: [ECKColony].self) { group -> [ECKColony] in
                for colony in colonies {
                    group.addTask {
                        let detailsResource = ECKPlanetaryColonyResource(token: self.character.token,
                                                                         colonyId: "\(colony.planet.planetId)")
                        let details = try await ECKWebService().loadResource(resource: detailsResource).response
                        return .init(colony: colony, details: details)
                    }
                }
                
                var colonies: [ECKColony] = []
                
                for try await result in group {
                    colonies.append(result)
                }
                
                return colonies.sorted(by: { $0.colony.planet.name < $1.colony.planet.name })
            }
            
            self.loadingState = .ready
        } catch {
            logger.error("Error loading planetary colonies \(error)")
            self.loadingState = .error
        }
    }
    
}
