//
//  IndustryActivitiesTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 16.10.25.
//

import Foundation
import SQLite

class IndustryActivitiesTable: SDETable {
    
    var table: SQLite.Table = .init("ramActivities")
    
    var activityIdColumn = Expression<Int64>("activityID")
    var activityNameColumn = Expression<String>("activityName")
    var activityDescriptionColumn = Expression<String>("description")
    var activityIconNoColumn = Expression<String?>("iconNo")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(activityIdColumn)
        table.column(activityNameColumn)
        table.column(activityDescriptionColumn)
        table.column(activityIconNoColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            activityIdColumn
        ))
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        try db.run(
            table.insert(
                activityIdColumn <- Int64(id),
                activityNameColumn <- data["name"] as! String,
                activityDescriptionColumn <- data["description"] as! String,
                activityIconNoColumn <- data["iconNo"] as? String
            )
        )
    }
    
}
