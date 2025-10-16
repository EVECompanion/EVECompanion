//
//  MarketGroupsTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 16.10.25.
//

import Foundation
import SQLite

class MarketGroupsTable: SDETable {
    
    var table: SQLite.Table = .init("invMarketGroups")
    
    var marketGroupIdColumn = Expression<Int64>("marketGroupID")
    var parentGroupIdColumn = Expression<Int64?>("parentGroupID")
    var marketGroupNameColumn = Expression<String>("marketGroupName")
    var marketGroupDescriptionColumn = Expression<String>("description")
    var hasTypesColumn = Expression<Bool>("hasTypes")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(marketGroupIdColumn)
        table.column(parentGroupIdColumn)
        table.column(marketGroupNameColumn)
        table.column(marketGroupDescriptionColumn)
        table.column(hasTypesColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            marketGroupIdColumn,
            parentGroupIdColumn
        ))
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        let parentGroupId: Int64?
        
        if let parentGroupIdInt = data["parentGroupID"] as? Int {
            parentGroupId = Int64(parentGroupIdInt)
        } else {
            parentGroupId = nil
        }
        
        try db.run(
            table.insert(
                marketGroupIdColumn <- Int64(id),
                parentGroupIdColumn <- parentGroupId,
                marketGroupNameColumn <- (data["name"] as! [String: Any])["en"] as! String,
                marketGroupDescriptionColumn <- ((data["description"] as? [String: Any])?["en"] as? String) ?? "",
                hasTypesColumn <- data["hasTypes"] as! Bool
            )
        )
    }
    
}
