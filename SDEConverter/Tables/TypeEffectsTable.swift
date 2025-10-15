//
//  TypeEffectsTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 15.10.25.
//

import Foundation
import SQLite

class TypeEffectsTable: SDETable {
    
    var table: SQLite.Table = .init("dgmTypeEffects")
    
    var typeIdColumn = Expression<Int64>("typeID")
    var effectIDColumn = Expression<Int64>("effectID")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(typeIdColumn)
        table.column(effectIDColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            effectIDColumn,
            typeIdColumn
        ))
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        try db.run(
            table.insert(
                typeIdColumn <- Int64(id),
                effectIDColumn <- Int64(data["effectID"] as! Int)
            )
        )
    }
    
}
