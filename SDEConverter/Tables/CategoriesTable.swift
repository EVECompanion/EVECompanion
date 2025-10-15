//
//  CategoriesTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 15.10.25.
//

import Foundation
import SQLite

class CategoriesTable: SDETable {
    
    var table: SQLite.Table = .init("invCategories")
    
    var categoryIdColumn = Expression<Int64>("categoryId")
    var categoryNameColumn = Expression<String>("categoryName")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(categoryIdColumn)
        table.column(categoryNameColumn)
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        try db.run(
            table.insert(
                categoryIdColumn <- Int64(id),
                categoryNameColumn <- (data["name"] as! [String: Any])["en"] as! String
            )
        )
    }
    
}
