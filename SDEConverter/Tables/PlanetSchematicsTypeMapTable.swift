//
//  PlanetSchematicsTypeMapTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 16.10.25.
//

import Foundation
import SQLite

class PlanetSchematicsTypeMapTable: SDETable {
    
    var table: SQLite.Table = .init("planetSchematicsTypeMap")
    
    var schematicIdColumn = Expression<Int64>("schematicID")
    var typeIdColumn = Expression<Int64>("typeID")
    var quantityColumn = Expression<Int64>("quantity")
    var isInputColumn = Expression<Bool>("isInput")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(schematicIdColumn)
        table.column(typeIdColumn)
        table.column(quantityColumn)
        table.column(isInputColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            schematicIdColumn
        ))
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        try db.run(
            table.insert(
                schematicIdColumn <- Int64(id),
                typeIdColumn <- Int64(data["typeID"] as! Int),
                quantityColumn <-  Int64(data["quantity"] as! Int),
                isInputColumn <- data["isInput"] as! Bool
            )
        )
    }
    
}
