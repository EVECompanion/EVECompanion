//
//  StationsTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 15.10.25.
//

import Foundation
import SQLite

class StationsTable: SDETable {
    
    var table: SQLite.Table = .init("staStations")
    
    var stationIdColumn = Expression<Int64>("stationID")
    var solarSystemIdColumn = Expression<Int64>("solarSystemID")
    var stationNameColumn = Expression<String>("stationName")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(stationIdColumn)
        table.column(solarSystemIdColumn)
        table.column(stationNameColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            stationIdColumn,
            solarSystemIdColumn
        ))
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        try db.run(
            table.insert(
                stationIdColumn <- Int64(id),
                solarSystemIdColumn <- Int64(data["solarSystemID"] as! Int),
                stationNameColumn <- data["name"] as! String
            )
        )
    }
    
}
