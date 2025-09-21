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
        await withTaskGroup { group in
            group.addTask {
                await self.loadESIFittings()
            }
            
            group.addTask {
                await self.loadLocalFittings()
            }
        }
    }
    
    @MainActor
    func loadESIFittings() async {
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
            esiLoadingState = .ready
        } catch {
            logger.error("Error while fetching character fittings \(error)")
            esiLoadingState = .error
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
    func loadLocalFittings() async {
        do {
            let fittingsFile = try getFittingsFileURL()
            let fittingsData = try Data(contentsOf: fittingsFile)
            
            self.loadedLocalFittings = try JSONDecoder().decode([ECKCharacterFitting].self, from: fittingsData)
        } catch {
            logger.error("Error loading local fittings: \(error)")
            return
        }
    }
    
    @MainActor
    public func createFitting(with ship: ECKItem) -> ECKCharacterFitting {
        let newFitting = ECKCharacterFitting(ship: ship)
        self.loadedLocalFittings.append(newFitting)
        Task {
            await saveLocalfittings()
        }
        return newFitting
    }
    
    @MainActor
    func saveLocalfittings() async {
        do {
            let fittingsFile = try getFittingsFileURL()
            let fittingsData = try JSONEncoder().encode(loadedLocalFittings)
            try fittingsData.write(to: fittingsFile, options: .atomic)
        } catch {
            logger.error("Error saving fittings: \(error)")
        }
    }
    
}
