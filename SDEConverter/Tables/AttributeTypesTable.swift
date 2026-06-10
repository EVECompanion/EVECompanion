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
    
    private let attributeIdColumn = SQLite.Expression<Int64>("attributeID")
    private let categoryIdColumn = SQLite.Expression<Int64?>("categoryID")
    private let attributeNameColumnn = SQLite.Expression<String?>("attributeName")
    private let attributeRawNameColumn = SQLite.Expression<String>("attributeRawName")
    private let attributeDisplayNameColumn = SQLite.Expression<String?>("displayName")
    private let highIsGoodColumn = SQLite.Expression<Bool>("highIsGood")
    private let stackableColumn = SQLite.Expression<Bool>("stackable")
    private let publishedColumn = SQLite.Expression<Bool>("published")
    private let defaultValueColumn = SQLite.Expression<Float64>("defaultValue")
    private let unitIdColumn = SQLite.Expression<Int64?>("unitID")
    
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
        
        let unitId: Int64?
        
        if let unit = data["unitID"] as? Int {
            unitId = Int64(unit)
        } else {
            unitId = nil
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
                unitIdColumn <- unitId
            )
        )
    }
    
}
