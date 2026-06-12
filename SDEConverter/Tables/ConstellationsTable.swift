//
//  ConstellationsTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 16.10.25.
//

import Foundation
import SQLite

class ConstellationsTable: SDETable {
    
    var table: SQLite.Table = .init("mapConstellations")
    
    var constellationIdColumn = SQLite.Expression<Int64>("constellationID")
    var regionIdColumn = SQLite.Expression<Int64>("regionID")
    var constellationNameColumn = SQLite.Expression<String>("constellationName")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(constellationIdColumn)
        table.column(regionIdColumn)
        table.column(constellationNameColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            constellationIdColumn,
            regionIdColumn,
            constellationNameColumn
        ))
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        try db.run(
            table.insert(
                constellationIdColumn <- Int64(id),
                regionIdColumn <- Int64(data["regionID"] as! Int),
                constellationNameColumn <- (data["name"] as! [String: Any])["en"] as! String
            )
        )
    }
    
}
