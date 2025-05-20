//
//  ECKCapitalRouteManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.03.25.
//

import Foundation

public class ECKCapitalRouteManager: ObservableObject {
    
    private let fileURL = URL.documentsDirectory.appending(path: "ECKCapitalRoutes.json")
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()
    
    @Published public private(set) var savedRoutes: [ECKCapitalJumpRoute]?
    
    public init() {
        loadRoutes()
    }
    
    public func addRoute(_ route: ECKCapitalJumpRoute) {
        // Copy the route to generate a new ID. This ensures that all saved routes have a different ID.
        let newRoute = ECKCapitalJumpRoute(name: route.name,
                                           destinationSystems: route.destinationSystems,
                                           avoidanceSystems: route.avoidanceSystems,
                                           jdcSkillLevel: route.jdcSkillLevel,
                                           jfcSkillLevel: route.jfcSkillLevel,
                                           jfSkillLevel: route.jfSkillLevel,
                                           ship: route.ship,
                                           route: route.route)
        
        if savedRoutes?.isEmpty ?? true {
            savedRoutes = [newRoute]
        } else {
            savedRoutes?.insert(newRoute, at: 0)
        }
        
        saveRoutes()
    }
    
    public func removeRoutes(_ indexSet: IndexSet) {
        self.savedRoutes?.remove(atOffsets: indexSet)
        saveRoutes()
    }
    
    private func loadRoutes() {
        do {
            let fileData = try Data(contentsOf: fileURL)
            self.savedRoutes = try decoder.decode([ECKCapitalJumpRoute].self, from: fileData)
        } catch {
            logger.error("Error reading capital routes file: \(error)")
            savedRoutes = []
        }
    }
    
    public func saveRoutes() {
        guard let savedRoutes else {
            return
        }
        
        do {
            let data = try encoder.encode(savedRoutes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Error writing capital routes file: \(error)")
        }
    }
    
}
