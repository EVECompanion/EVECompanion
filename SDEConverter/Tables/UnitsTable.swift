//
//  UnitsTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 15.10.25.
//

import Foundation
import SQLite

class UnitsTable: SDETable {
    
    var table: SQLite.Table = .init("eveUnits")
    
    var unitIdColumn = Expression<Int64>("unitID")
    var unitNameColumn = Expression<String>("unitName")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(unitIdColumn)
        table.column(unitNameColumn)
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        try db.run(
            table.insert(
                unitIdColumn <- Int64(id),
                unitNameColumn <- data["name"] as! String
            )
        )
    }
    
}
