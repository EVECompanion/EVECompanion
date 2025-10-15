//
//  GroupsTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 15.10.25.
//

import Foundation
import SQLite

class GroupsTable: SDETable {
    
    var table: SQLite.Table = .init("invGroups")
    
    var groupIdColumn = Expression<Int64>("groupID")
    var groupNameColumn = Expression<String>("groupName")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(groupIdColumn)
        table.column(groupNameColumn)
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        try db.run(
            table.insert(
                groupIdColumn <- Int64(id),
                groupNameColumn <- data["name"] as! String
            )
        )
    }
    
}
