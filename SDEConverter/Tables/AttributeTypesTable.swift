//
//  AttributeTypesTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 14.10.25.
//

import Foundation
import SQLite

class AttributeTypesTable: SDETable {
    
    let table: SQLite.Table = .init("dgmAttributeTypes")
    
    private let attributeIdColumn = Expression<Int64>("attributeID")
    private let categoryIdColumn = Expression<Int64?>("categoryID")
    private let attributeNameColumnn = Expression<String?>("attributeName")
    private let attributeRawNameColumn = Expression<String>("attributeRawName")
    private let attributeDisplayNameColumn = Expression<String?>("displayName")
    private let highIsGoodColumn = Expression<Bool>("highIsGood")
    private let stackableColumn = Expression<Bool>("stackable")
    private let publishedColumn = Expression<Bool>("published")
    private let defaultValueColumn = Expression<Float64>("defaultValue")
    private let unitIdColumn = Expression<Int64>("unitID")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(attributeIdColumn)
        table.column(categoryIdColumn)
        table.column(attributeNameColumnn)
        table.column(attributeRawNameColumn)
        table.column(attributeDisplayNameColumn)
        table.column(highIsGoodColumn)
        table.column(stackableColumn)
        table.column(publishedColumn)
        table.column(defaultValueColumn)
        table.column(unitIdColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            attributeIdColumn,
            categoryIdColumn,
            attributeRawNameColumn
        ))
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        let categoryId: Int64?
        
        if let category = data["attributeCategoryID"] as? Int {
            categoryId = Int64(category)
        } else {
            categoryId = nil
        }
        
        try db.run(
            table.insert(
                attributeIdColumn <- Int64(id),
                categoryIdColumn <- categoryId,
                attributeNameColumnn <- (data["displayName"] as? [String: String])?["en"],
                attributeDisplayNameColumn <- (data["displayName"] as? [String: String])?["en"],
                attributeRawNameColumn <- data["name"] as! String,
                highIsGoodColumn <- data["highIsGood"] as! Bool,
                stackableColumn <- data["stackable"] as! Bool,
                publishedColumn <- data["published"] as! Bool,
                defaultValueColumn <- Float64(data["defaultValue"] as! Double),
                unitIdColumn <- Int64(data["dataType"] as! Int)
            )
        )
    }
    
}
