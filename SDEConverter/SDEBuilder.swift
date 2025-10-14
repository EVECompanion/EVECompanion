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
    }
    
    private func fillTables() throws {
        try fillTypesTable()
    }
    
    private func fillTypesTable() throws {
        let table = TypesTable()
        let fileContent = try SDEFile.types.loadFile(sdeDir: sdeDir)
        
        for type in fileContent {
            try table.add(id: Int(type.key)!, data: type.value, to: db)
        }
    }
    
}
