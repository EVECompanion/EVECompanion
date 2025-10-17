
//
//  CapitalJumpDistancesTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 16.10.25.
//

import Foundation
import SQLite

class CapitalJumpDistancesTable {
    
    var table: SQLite.Table
    
    var startSystemIdColumn = Expression<Int64>("startSystemID")
    var destinationSystemIdColumn = Expression<Int64>("destinationSystemID")
    var distanceColumn = Expression<Float64>("distance")
    
    init(tableName: String = "mapCapitalJumpDistances") {
        self.table = .init(tableName)
    }
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(startSystemIdColumn)
        table.column(destinationSystemIdColumn)
        table.column(distanceColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            startSystemIdColumn,
            destinationSystemIdColumn
        ))
    }
    
    func createTable(in connection: Connection) throws {
        try connection.run(table.create(block: { table in
            self.addColumns(to: table)
        }))
        
        try createIndexes(connection: connection)
    }
    
    struct Entry {
        let startSystemId: Int64
        let destinationSystemId: Int64
        let distance: Float64
    }
    
    func add(entry: Entry, to db: SQLite.Connection) throws {
        try db.run(
            table.insert(
                startSystemIdColumn <- entry.startSystemId,
                destinationSystemIdColumn <- entry.destinationSystemId,
                distanceColumn <- entry.distance / 9460000000000000
            )
        )
    }
    
}
