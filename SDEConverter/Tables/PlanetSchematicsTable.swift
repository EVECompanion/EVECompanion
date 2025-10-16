//
//  PlanetSchematicsTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 16.10.25.
//

import Foundation
import SQLite

class PlanetSchematicsTable: SDETable {
    
    var table: SQLite.Table = .init("planetSchematics")
    
    var schematicIdColumn = Expression<Int64>("schematicID")
    var schematicNameColumn = Expression<String>("schematicName")
    var cycleTimeColumn = Expression<Int64>("cycleTime")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(schematicIdColumn)
        table.column(schematicNameColumn)
        table.column(cycleTimeColumn)
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
                schematicNameColumn <- (data["name"] as! [String: Any])["en"] as! String,
                cycleTimeColumn <- Int64(data["cycleTime"] as! Int)
            )
        )
    }
    
}
