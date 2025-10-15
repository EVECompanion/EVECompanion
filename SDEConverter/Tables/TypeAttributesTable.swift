//
//  TypeAttributesTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 14.10.25.
//

import Foundation
import SQLite

class TypeAttributesTable: SDETable {
    
    var table: SQLite.Table = .init("dgmTypeAttributes")
    
    private let typeIdColumn = Expression<Int64>("typeID")
    private let attributeIdColumn = Expression<Int64>("attributeID")
    private let valueIntColumn = Expression<Int64?>("valueInt")
    private let valueFloatColumn = Expression<Float64>("valueFloat")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(typeIdColumn)
        table.column(attributeIdColumn)
        table.column(valueIntColumn)
        table.column(valueFloatColumn)
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        try db.run(
            table.insert(
                typeIdColumn <- Int64(id),
                attributeIdColumn <- Int64(data["attributeID"] as! Int),
                valueFloatColumn <- Float64(data["value"] as! Double)
            )
        )
    }
    
}
