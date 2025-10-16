//
//  FactionsTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 16.10.25.
//

import Foundation
import SQLite

class FactionsTable: SDETable {
    
    var table: SQLite.Table = .init("chrFactions")
    
    var factionIdColumn = Expression<Int64>("factionID")
    var factionNameColumn = Expression<String>("factionName")
    var factionDescriptionColumn = Expression<String>("description")
    var iconIdColumn = Expression<Int64>("iconID")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(factionIdColumn)
        table.column(factionNameColumn)
        table.column(factionDescriptionColumn)
        table.column(iconIdColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            factionIdColumn
        ))
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {        
        try db.run(
            table.insert(
                factionIdColumn <- Int64(id),
                factionNameColumn <- (data["name"] as! [String: Any])["en"] as! String,
                factionDescriptionColumn <- (data["description"] as! [String: Any])["en"] as! String,
                iconIdColumn <- Int64(data["iconID"] as! Int)
            )
        )
    }
    
}
