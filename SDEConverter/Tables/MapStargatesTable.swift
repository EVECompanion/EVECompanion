//
//  MapStargatesTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 20.05.26.
//

import Foundation
import SQLite

class MapStargatesTable: SDETable {
    
    var table: SQLite.Table = .init("mapStargates")
    
    var stargateIDColumn = SQLite.Expression<Int64>("stargateID")
    var solarSystemIDColumn = SQLite.Expression<Int64>("solarSystemID")
    var destinationSolarSystemIDColumn = SQLite.Expression<Int64>("destinationSolarSystemID")
    var destinationStargateIDColumn = SQLite.Expression<Int64>("destinationStargateID")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(stargateIDColumn)
        table.column(solarSystemIDColumn)
        table.column(destinationSolarSystemIDColumn)
        table.column(destinationStargateIDColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            solarSystemIDColumn,
            destinationSolarSystemIDColumn
        ))
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        try db.run(
            table.insert(
                stargateIDColumn <- Int64(id),
                solarSystemIDColumn <- Int64(data["solarSystemID"] as! Int),
                destinationSolarSystemIDColumn <- Int64((data["destination"] as! [String: Any])["solarSystemID"] as! Int),
                destinationStargateIDColumn <- Int64((data["destination"] as! [String: Any])["stargateID"] as! Int)
            )
        )
    }
    
}
