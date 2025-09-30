//
//  ECKFittingManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.25.
//

public import Combine

public class ECKFittingManager: ObservableObject {
    
    public let character: ECKCharacter
    public let isPreview: Bool
    
    @Published var loadedLocalFittings: [ECKCharacterFitting] = []
    public var localFittings: [ECKCharacterFitting] {
        if searchText.isEmpty == false {
            return loadedLocalFittings.filter { fitting in
                return fitting.name.lowercased().contains(searchText.lowercased())
                || fitting.ship.item.name.lowercased().contains(searchText.lowercased())
            }
        } else {
            return loadedLocalFittings
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
        do {
            let fittingsFile = try getFittingsFileURL()
            let fittingsData = try Data(contentsOf: fittingsFile)
            
            self.loadedLocalFittings = try JSONDecoder().decode([ECKCharacterFitting].self, from: fittingsData)
        } catch {
            logger.error("Error loading local fittings: \(error)")
            return
        }
    }
    
    func getFittingsFileURL() throws -> URL {
        let documentsDir = try FileManager.default.url(for: .documentDirectory,
                                                       in: .userDomainMask,
                                                       appropriateFor: nil,
                                                       create: true)
        return documentsDir.appendingPathComponent("fittings.json")
    }
    
    @MainActor
    public func createFitting(with ship: ECKItem) -> ECKCharacterFitting {
        let newFitting = ECKCharacterFitting(ship: ship)
        self.loadedLocalFittings.append(newFitting)
        // TODO: Save
        return newFitting
    }
    
    @MainActor
    public func importFitting(_ fitting: ECKCharacterFitting) {
        self.loadedLocalFittings.append(fitting)
        // TODO: Save
    }
    
}
