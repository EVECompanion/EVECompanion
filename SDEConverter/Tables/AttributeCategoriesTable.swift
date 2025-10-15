//
//  AttributeCategoriesTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 15.10.25.
//

import Foundation
import SQLite

class AttributeCategoriesTable: SDETable {
    
    var table: SQLite.Table = .init("dgmAttributeCategories")
    
    var categoryIdColumn = Expression<Int64>("categoryID")
    var categoryNameColumn = Expression<String>("categoryName")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(categoryIdColumn)
        table.column(categoryNameColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            categoryIdColumn
        ))
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        try db.run(
            table.insert(
                categoryIdColumn <- Int64(id),
                categoryNameColumn <- data["name"] as! String
            )
        )
    }
    
}
