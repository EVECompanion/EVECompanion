//
//  MapDenormalizeTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 15.10.25.
//

import Foundation
import SQLite

class MapDenormalizeTable: SDETable {
    
    var table: SQLite.Table = .init("mapDenormalize")
    
    var itemIdColumn = Expression<Int64>("itemID")
    var itemNameColumn = Expression<String>("itemName")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(itemIdColumn)
        table.column(itemNameColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            itemIdColumn
        ))
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        try db.run(
            table.insert(
                itemIdColumn <- Int64(id),
                itemNameColumn <- data["name"] as! String
            )
        )
    }
    
}
