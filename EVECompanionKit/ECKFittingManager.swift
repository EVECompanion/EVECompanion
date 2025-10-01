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
            let fittingsDir = try getFittingsDirectory()
            let fittingURLs = try FileManager.default.contentsOfDirectory(at: fittingsDir,
                                                                          includingPropertiesForKeys: nil)
            
            var fittings: [ECKCharacterFitting] = []
            let decoder = JSONDecoder()
            
            for fittingURL in fittingURLs {
                do {
                    let fittingData = try Data(contentsOf: fittingURL)
                    let fitting = try decoder.decode(ECKCharacterFitting.self, from: fittingData)
                    fittings.append(fitting)
                } catch {
                    logger.error("Cannot load local fitting: \(error)")
                    continue
                }
            }
            
            self.loadedLocalFittings = fittings
        } catch {
            logger.error("Error loading local fittings: \(error)")
            return
        }
    }
    
    private func getDocumentsDirectory() throws -> URL {
        return try FileManager.default.url(for: .documentDirectory,
                                           in: .userDomainMask,
                                           appropriateFor: nil,
                                           create: true)
    }
    
    private func getFittingsDirectory() throws -> URL {
        let documentsDir = try getDocumentsDirectory()
        let fittingsDir = documentsDir.appendingPathComponent("fittings", isDirectory: true)
        
        if FileManager.default.fileExists(atPath: fittingsDir.path) == false {
            try FileManager.default.createDirectory(at: fittingsDir, withIntermediateDirectories: true)
        }
        
        return fittingsDir
    }
    
    private func getFittingFileURL(_ fitting: ECKCharacterFitting) throws -> URL {
        let fittingsDirectoryUrl = try getFittingsDirectory()
        return fittingsDirectoryUrl.appendingPathComponent("\(fitting.fittingId.uuidString).json", isDirectory: false)
    }
    
    @MainActor
    public func createFitting(with ship: ECKItem) -> ECKCharacterFitting {
        let newFitting = ECKCharacterFitting(ship: ship)
        self.loadedLocalFittings.append(newFitting)
        saveFitting(newFitting)
        return newFitting
    }
    
    @MainActor
    public func importFitting(_ fitting: ECKCharacterFitting) {
        self.loadedLocalFittings.append(fitting)
        saveFitting(fitting)
    }
    
    public func saveFitting(_ fitting: ECKCharacterFitting) {
        do {
            let fittingFileURL = try getFittingFileURL(fitting)
            let data = try JSONEncoder().encode(fitting)
            try data.write(to: fittingFileURL, options: .atomic)
        } catch {
            logger.error("Error saving fitting: \(error)")
        }
    }
    
}
