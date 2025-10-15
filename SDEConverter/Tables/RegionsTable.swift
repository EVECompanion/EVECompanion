//
//  RegionsTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 15.10.25.
//

import Foundation
import SQLite

class RegionsTable: SDETable {
    
    var table: SQLite.Table = .init("mapRegions")
    
    var regionIdColumn = Expression<Int64>("regionID")
    var regionNameColumn = Expression<String>("regionName")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(regionIdColumn)
        table.column(regionNameColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            regionIdColumn
        ))
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        try db.run(
            table.insert(
                regionIdColumn <- Int64(id),
                regionNameColumn <- (data["name"] as! [String: Any])["en"]! as! String
            )
        )
    }
    
}
