//
//  SDEBuilder.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 14.10.25.
//

import Foundation
import SQLite

class SDEBuilder {
    
    private let db: Connection
    private let sdeDir: String
    
    init(sdeDir: String, outputFile: String) throws {
        self.sdeDir = sdeDir
        self.db = try Connection(outputFile)
    }
    
    func run() throws {
        try createTables()
        try fillTables()
    }
    
    private func createTables() throws {
        try TypesTable().createTable(in: db)
        try AttributeTypesTable().createTable(in: db)
        try TypeAttributesTable().createTable(in: db)
        try AttributeCategoriesTable().createTable(in: db)
        try GroupsTable().createTable(in: db)
        try CategoriesTable().createTable(in: db)
        try TraitsTable().createTable(in: db)
        try MapDenormalizeTable().createTable(in: db)
        try TypeEffectsTable().createTable(in: db)
        try UnitsTable().createTable(in: db)
        try StationsTable().createTable(in: db)
        try SolarSystemsTable().createTable(in: db)
        try RegionsTable().createTable(in: db)
        try ConstellationsTable().createTable(in: db)
        try FactionsTable().createTable(in: db)
        try MarketGroupsTable().createTable(in: db)
    }
    
    private func fillTables() throws {
        try fillMarketGroupsTable()
        try fillFactionsTable()
        try fillConstellationsTable()
        try fillRegionsTable()
        try fillSolarSystemsTable()
        try fillStationsTable()
        try fillTypesTable()
        try fillGroupsTable()
        try fillUnitsTable()
        try fillTypeDogmaTables()
        try fillMapDenormalizeTable()
        try fillTraitsTable()
        try fillCategoriesTable()
        try fillAttributeCategoriesTable()
        try fillAttributeTypesTable()
    }
    
    private func fillTypesTable() throws {
        print("Filling types table.")
        let table = TypesTable()
        let fileContent = try SDEFile.types.loadFile(sdeDir: sdeDir)
        
        for type in fileContent {
            try table.add(id: Int(type.key)!, data: type.value, to: db)
        }
        print("Done filling types table.")
    }
    
    private func fillAttributeTypesTable() throws {
        print("Filling Attribute Types Table.")
        
        let table = AttributeTypesTable()
        let fileContent = try SDEFile.attributes.loadFile(sdeDir: sdeDir)
        
        for attribute in fileContent {
            try table.add(id: Int(attribute.key)!, data: attribute.value, to: db)
        }
        
        print("Done filling Attribute Types Table.")
    }
    
    private func fillTypeDogmaTables() throws {
        print("Filling Type Attributes Table")
        
        let typeAttributesTable = TypeAttributesTable()
        let typeEffectsTable = TypeEffectsTable()
        let fileContent = try SDEFile.typeDogma.loadFile(sdeDir: sdeDir)
        
        for type in fileContent {
            let dogmaAttributes: [[String: Any]] = (type.value["dogmaAttributes"] as? [[String: Any]]) ?? []
            
            for dogmaAttribute in dogmaAttributes {
                try typeAttributesTable.add(id: Int(type.key)!, data: dogmaAttribute, to: db)
            }
            
            let effects: [[String: Any]] = (type.value["dogmaEffects"] as? [[String: Any]]) ?? []
            
            for effect in effects {
                try typeEffectsTable.add(id: Int(type.key)!, data: effect, to: db)
            }
        }
        
        print("Done filling Type Attributes Table")
    }
    
    private func fillAttributeCategoriesTable() throws {
        print("Filling Attribute Categories Table.")
        
        let typeAttributesTable = AttributeCategoriesTable()
        let fileContent = try SDEFile.attributeCategories.loadFile(sdeDir: sdeDir)
        
        for category in fileContent {
            try typeAttributesTable.add(id: Int(category.key)!, data: category.value, to: db)
        }
        
        print("Done Filling Attribute Categories Table.")
    }
    
    private func fillGroupsTable() throws {
        print("Filling Groups Table.")
        
        let typeAttributesTable = GroupsTable()
        let fileContent = try SDEFile.groups.loadFile(sdeDir: sdeDir)
        
        for category in fileContent {
            try typeAttributesTable.add(id: Int(category.key)!, data: category.value, to: db)
        }
        
        print("Done filling Groups Table.")
    }
    
    private func fillCategoriesTable() throws {
        print("Filling Categories Table.")
        
        let categoriesTable = CategoriesTable()
        let fileContent = try SDEFile.categories.loadFile(sdeDir: sdeDir)
        
        for category in fileContent {
            try categoriesTable.add(id: Int(category.key)!, data: category.value, to: db)
        }
        
        print("Done filling Categories Table.")
    }
    
    private func fillTraitsTable() throws {
        print("Filling Traits Table.")
        
        let traitsTable = TraitsTable()
        let fileContent = try SDEFile.traits.loadFile(sdeDir: sdeDir)
        
        for trait in fileContent {
            try traitsTable.add(id: Int(trait.key)!, data: trait.value, to: db)
        }
        
        print("Done filling Traits Table.")
    }
    
    private func fillMapDenormalizeTable() throws {
        print("Filling Map Denormalize Table.")
        
        let mapTable = MapDenormalizeTable()
        
        let solarSystemsFileContent = try SDEFile.solarSystems.loadFile(sdeDir: sdeDir)
        
        for solarSystem in solarSystemsFileContent {
            var data = solarSystem.value
            
            data["name"] = (data["name"] as! [String: Any])["en"] as! String
            
            try mapTable.add(id: Int(solarSystem.key)!, data: data, to: db)
        }
        
        let planetsFileContent = try SDEFile.planets.loadFile(sdeDir: sdeDir)
        
        for planet in planetsFileContent {
            var data: [String: Any] = planet.value
            
            let statement = try db.prepare("""
                SELECT itemName from mapDenormalize WHERE itemID = ?
            """, planet.value["solarSystemID"] as! Int)
            
            let result = try statement.run().makeIterator().failableNext()
            let systemName = result!.first as! String
            let planetIndex = data["celestialIndex"] as! Int
            data["name"] = "\(systemName) \(romanNumeral(for: planetIndex))"
            
            try mapTable.add(id: Int(planet.key)!, data: data, to: db)
        }
        
        print("Done filling Map Denormalize Table.")
    }
    
    private func romanNumeral(for int: Int) -> String {
        var integerValue = int
        // Roman numerals cannot be represented in integers greater than 3999
        if int >= 4000 {
            fatalError("Invalid input (greater than 3999)")
        }
        var numeralString = ""
        let mappingList: [(Int, String)] = [(1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"), (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
        for i in mappingList {
            while (integerValue >= i.0) {
                integerValue -= i.0
                numeralString += i.1
            }
        }
        return numeralString
    }
    
    private func fillUnitsTable() throws {
        print("Filling Units Table.")
        
        let unitsTable = UnitsTable()
        let fileContent = try SDEFile.units.loadFile(sdeDir: sdeDir)
        
        for unit in fileContent {
            try unitsTable.add(id: Int(unit.key)!, data: unit.value, to: db)
        }
        
        print("Done filling Units Table.")
    }
    
    private func fillStationsTable() throws {
        print("Filling Stations Table.")
        
        let stationsTable = StationsTable()
        let fileContent = try SDEFile.stations.loadFile(sdeDir: sdeDir)
        
        let moons = try SDEFile.moons.loadFile(sdeDir: sdeDir)
        let planets = try SDEFile.planets.loadFile(sdeDir: sdeDir)
        let npcCorps = try SDEFile.npcCorps.loadFile(sdeDir: sdeDir)
        let operations = try SDEFile.stationOperations.loadFile(sdeDir: sdeDir)
        let solarSystems = try SDEFile.solarSystems.loadFile(sdeDir: sdeDir)
        
        for station in fileContent {
            let solarSystemId = station.value["solarSystemID"] as! Int
            let orbitId = station.value["orbitID"] as! Int
            let corporationId = station.value["ownerID"] as! Int
            let operationId = station.value["operationID"] as! Int
            
            let moon = moons["\(orbitId)"]
            let moonNumber = moon?["orbitIndex"] as? Int
            let moonOrbitId = moon?["orbitID"] as? Int
            
            let planet = planets["\(moonOrbitId ?? orbitId)"]
            let planetUniqueName = (planet?["uniqueName"] as? [String: Any])?["en"] as? String
            let planetNumber = planet?["celestialIndex"] as? Int
            
            let corpName = (npcCorps["\(corporationId)"]!["name"] as! [String: Any])["en"]!
            let operation = (operations["\(operationId)"]!["operationName"] as! [String: Any])["en"]!
            
            let solarSystemDict = solarSystems["\(solarSystemId)"]
            let solarSystemName = (solarSystemDict!["name"] as! [String: Any])["en"]!
            
            var name = "\(solarSystemName) "
            
            if let planetUniqueName {
                name += "\(planetUniqueName) - "
            } else if let planetNumber {
                name += "\(romanNumeral(for: planetNumber)) - "
            } else {
                name += "- "
            }
            
            if let moonNumber {
                name += "Moon \(romanNumeral(for: moonNumber)) - "
            }
            
            name += "\(corpName) \(operation)"
            
            var data = station.value
            data["name"] = name
            
            try stationsTable.add(id: Int(station.key)!, data: data, to: db)
        }
        
        print("Done filling Stations Table.")
    }
    
    private func fillSolarSystemsTable() throws {
        print("Filling Solar Systems Table.")
        
        let traitsTable = SolarSystemsTable()
        let fileContent = try SDEFile.solarSystems.loadFile(sdeDir: sdeDir)
        
        let suns = try SDEFile.suns.loadFile(sdeDir: sdeDir)
        
        for solarSystem in fileContent {
            var data = solarSystem.value
            
            let sunId = data["starID"] as? Int
            if let sunId {
                data["sunTypeID"] = suns["\(sunId)"]?["typeID"] as? Int
            }
                
            try traitsTable.add(id: Int(solarSystem.key)!, data: data, to: db)
        }
        
        print("Done filling Solar Systems Table.")
    }
    
    private func fillRegionsTable() throws {
        print("Filling Regions Table.")
        
        let traitsTable = RegionsTable()
        let fileContent = try SDEFile.regions.loadFile(sdeDir: sdeDir)
        
        for region in fileContent {
            try traitsTable.add(id: Int(region.key)!, data: region.value, to: db)
        }
        
        print("Done filling Regions Table.")
    }
    
    private func fillConstellationsTable() throws {
        print("Filling Constellations Table.")
        
        let constellationsTable = ConstellationsTable()
        let fileContent = try SDEFile.constellations.loadFile(sdeDir: sdeDir)
        
        for constellation in fileContent {
            try constellationsTable.add(id: Int(constellation.key)!, data: constellation.value, to: db)
        }
        
        print("Done filling Constellations Table.")
    }
    
    private func fillFactionsTable() throws {
        print("Filling Factions Table.")
        
        let factionsTable = FactionsTable()
        let fileContent = try SDEFile.factions.loadFile(sdeDir: sdeDir)
        
        for faction in fileContent {
            try factionsTable.add(id: Int(faction.key)!, data: faction.value, to: db)
        }
        
        print("Done filling Factions Table.")
    }
    
    private func fillMarketGroupsTable() throws {
        print("Filling Market Groups Table.")
        
        let marketGroupsTable = MarketGroupsTable()
        let fileContent = try SDEFile.marketGroups.loadFile(sdeDir: sdeDir)
        
        for marketGroup in fileContent {
            try marketGroupsTable.add(id: Int(marketGroup.key)!, data: marketGroup.value, to: db)
        }
        
        print("Done filling Market Groups Table.")
    }
    
}
