//
//  SDETable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 14.10.25.
//

import SQLite

protocol SDETable {
    
    var table: Table { get }
    
    func addColumns(to table: TableBuilder)
    func createIndexes(connection: Connection) throws
    func add(id: Int, data: [String: Any], to db: Connection) throws
    
}

extension SDETable {
    
    func createTable(in connection: Connection) throws {
        try connection.run(table.create(block: { table in
            self.addColumns(to: table)
        }))
        
        try createIndexes(connection: connection)
    }
    
}
