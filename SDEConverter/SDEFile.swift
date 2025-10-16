//
//  SDEFile.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 14.10.25.
//

import Foundation
import Yams

enum SDEFile {
    
    case constellations
    case types
    case typeDogma
    case attributes
    case attributeCategories
    case categories
    case groups
    case moons
    case npcCorps
    case solarSystems
    case planets
    case regions
    case stations
    case stationOperations
    case suns
    case traits
    case units
    
    private var fileName: String {
        switch self {
        case .types:
            return "types.yaml"
        case .attributes:
            return "dogmaAttributes.yaml"
        case .typeDogma:
            return "typeDogma.yaml"
        case .attributeCategories:
            return "dogmaAttributeCategories.yaml"
        case .groups:
            return "groups.yaml"
        case .categories:
            return "categories.yaml"
        case .traits:
            return "typeBonus.yaml"
        case .planets:
            return "mapPlanets.yaml"
        case .solarSystems:
            return "mapSolarSystems.yaml"
        case .units:
            return "dogmaUnits.yaml"
        case .stations:
            return "npcStations.yaml"
        case .moons:
            return "mapMoons.yaml"
        case .npcCorps:
            return "npcCorporations.yaml"
        case .stationOperations:
            return "stationOperations.yaml"
        case .suns:
            return "mapStars.yaml"
        case .regions:
            return "mapRegions.yaml"
        case .constellations:
            return "mapConstellations.yaml"
        }
    }
    
    func loadFile(sdeDir: String) throws -> [String: [String: Any]] {
        let fileContentString = try loadFileContent(sdeDir: sdeDir)
        print("Parsing yaml for file \(fileName)")
        
        let decodedFileContent = try Yams.load(yaml: fileContentString)
        
        guard let decodedFileContent = decodedFileContent as? [String: [String: Any]] else {
            print("Cannot read file content of file \(fileName) as expected")
            fatalError()
        }
        
        return decodedFileContent
    }
    
    private func loadFileContent(sdeDir: String) throws -> String {
        print("Loading \(fileName)")
        return try String(contentsOfFile: "\(sdeDir)/\(fileName)", encoding: .utf8)
    }
    
}
