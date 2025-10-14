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
    }
    
    private func fillTables() throws {
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
    
}
