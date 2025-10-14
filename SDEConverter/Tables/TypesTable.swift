//
//  TypesTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 14.10.25.
//

import Foundation
import SQLite

class TypesTable: SDETable {
    
    var table: SQLite.Table = .init("invTypes")
    
    private let typeIdColumn = Expression<Int64>("typeID")
    private let groupIdColumn = Expression<Int64>("groupID")
    private let typeNameColumn = Expression<String>("typeName")
    private let descriptionColumn = Expression<String?>("description")
    private let massColumn = Expression<Float64>("mass")
    private let volumeColumn = Expression<Float64>("volume")
    private let capacityColumn = Expression<Float64>("capacity")
    private let radiusColumn = Expression<Float64>("radius")
    private let iconIdColumn = Expression<Int64?>("iconID")
    private let publishedColumn = Expression<Bool>("published")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(typeIdColumn)
        table.column(groupIdColumn)
        table.column(typeNameColumn)
        table.column(descriptionColumn)
        table.column(massColumn)
        table.column(volumeColumn)
        table.column(capacityColumn)
        table.column(radiusColumn)
        table.column(iconIdColumn)
        table.column(publishedColumn)
    }
    
    func add(id: Int, data: [String : Any], to db: Connection) throws {
        let iconId: Int64?
        
        if let iconIdInt = data["iconID"] as? Int {
            iconId = Int64(iconIdInt)
        } else {
            iconId = nil
        }
        
        try db.run(
            table.insert(
                typeIdColumn <- Int64(id),
                groupIdColumn <- Int64(data["groupID"] as! Int),
                typeNameColumn <- (data["name"] as! [String: String])["en"]!,
                descriptionColumn <- (data["description"] as? [String: String])?["en"],
                massColumn <- Float64(data["mass"] as? Double ?? 0.0),
                volumeColumn <- Float64(data["volume"] as? Double ?? 0.0),
                capacityColumn <- Float64(data["capacity"] as? Double ?? 0.0),
                radiusColumn <- Float64(data["radius"] as? Double ?? 0.0),
                iconIdColumn <- iconId,
                publishedColumn <- data["published"] as! Bool
            )
        )
    }
    
}
