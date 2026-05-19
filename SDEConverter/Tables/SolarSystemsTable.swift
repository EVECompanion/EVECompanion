//
//  SolarSystemsTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 15.10.25.
//

import Foundation
import SQLite

class SolarSystemsTable: SDETable {
    
    var table: SQLite.Table = .init("mapSolarSystems")
    
    var solarSystemIdColumn = Expression<Int64>("solarSystemID")
    var constellationIdColumn = Expression<Int64>("constellationID")
    var regionIdColumn = Expression<Int64>("regionID")
    var solarSystemNameColumn = Expression<String>("solarSystemName")
    var securityColumn = Expression<Float64>("security")
    var sunTypeIdColumn = Expression<Int64?>("sunTypeID")
    var xColumn = Expression<Float64>("x")
    var yColumn = Expression<Float64>("y")
    var zColumn = Expression<Float64>("z")
    var position2dxColumn = Expression<Float64?>("2dx")
    var position2dyColumn = Expression<Float64?>("2dy")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(solarSystemIdColumn)
        table.column(constellationIdColumn)
        table.column(regionIdColumn)
        table.column(solarSystemNameColumn)
        table.column(securityColumn)
        table.column(sunTypeIdColumn)
        table.column(xColumn)
        table.column(yColumn)
        table.column(zColumn)
        table.column(position2dxColumn)
        table.column(position2dyColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            solarSystemIdColumn,
            constellationIdColumn,
            regionIdColumn,
            solarSystemNameColumn
        ))
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        let position = data["position"] as! [String: Any]
        
        let sunTypeId: Int64?
        
        if let sunTypeIdInt = data["sunTypeID"] as? Int {
            sunTypeId = Int64(sunTypeIdInt)
        } else {
            sunTypeId = nil
        }
        
        let position2d = data["position2D"] as? [String: Any]
        
        let position2dx: Float64?
        if let position2dxDouble = position2d?["x"] as? Double {
            position2dx = Float64(position2dxDouble)
        } else {
            position2dx = nil
        }
        
        let position2dy: Float64?
        if let position2dyDouble = position2d?["y"] as? Double {
            position2dy = Float64(position2dyDouble)
        } else {
            position2dy = nil
        }
        
        try db.run(
            table.insert(
                solarSystemIdColumn <- Int64(id),
                constellationIdColumn <- Int64(data["constellationID"] as! Int),
                regionIdColumn <- Int64(data["regionID"] as! Int),
                solarSystemNameColumn <- (data["name"] as! [String: Any])["en"] as! String,
                securityColumn <- Float64(data["securityStatus"] as! Double),
                sunTypeIdColumn <- sunTypeId,
                xColumn <- Float64(position["x"] as! Double),
                yColumn <- Float64(position["y"] as! Double),
                zColumn <- Float64(position["z"] as! Double),
                position2dxColumn <- position2dx,
                position2dyColumn <- position2dy
            )
        )
    }
    
}
