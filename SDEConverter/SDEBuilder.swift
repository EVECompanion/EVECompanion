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
    }
    
    private func fillTables() throws {
        try fillMapDenormalizeTable()
        try fillTraitsTable()
        try fillCategoriesTable()
        try fillGroupsTable()
        try fillAttributeCategoriesTable()
        try fillTypeDogmaTables()
        try fillTypesTable()
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
        let fileContent = try SDEFile.typeDogma.loadFile(sdeDir: sdeDir)
        
        for type in fileContent {
            let dogmaAttributes: [[String: Any]] = (type.value["dogmaAttributes"] as? [[String: Any]]) ?? []
            
            for dogmaAttribute in dogmaAttributes {
                try typeAttributesTable.add(id: Int(type.key)!, data: dogmaAttribute, to: db)
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
        let fileContent = try SDEFile.attributeCategories.loadFile(sdeDir: sdeDir)
        
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
        
        let categoriesTable = TraitsTable()
        let fileContent = try SDEFile.traits.loadFile(sdeDir: sdeDir)
        
        for trait in fileContent {
            try categoriesTable.add(id: Int(trait.key)!, data: trait.value, to: db)
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
    
}
