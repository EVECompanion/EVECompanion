//
//  DogmaEffectsTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 16.10.25.
//

import Foundation
import SQLite
import Yams

class DogmaEffectsTable: SDETable {
    
    var table: SQLite.Table = .init("dgmEffects")
    
    private let effectIdColumn = Expression<Int64>("effectID")
    private let effectNameColumn = Expression<String>("effectName")
    private let effectCategoryColumn = Expression<Int64?>("effectCategory")
    private let modifierInfoColumn = Expression<String>("modifierInfo")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(effectIdColumn)
        table.column(effectNameColumn)
        table.column(effectCategoryColumn)
        table.column(modifierInfoColumn)
    }
    
    func createIndexes(connection: Connection) throws {
        try connection.run(table.createIndex(
            effectIdColumn,
            effectNameColumn
        ))
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        let effectCategory: Int64?
        
        if let effectCategoryId = data["effectCategoryID"] as? Int {
            effectCategory = Int64(effectCategoryId)
        } else {
            effectCategory = nil
        }
        
        let modifierInfo: String
        
        if let modifierInfoData = data["modifierInfo"] as? [[String: Any]] {
            modifierInfo = try Yams.serialize(node: ["a": modifierInfoData].represented()).split(separator: "\n").dropFirst().joined(separator: "\n")
        } else {
            modifierInfo = "null\n...\n"
        }
        
        try db.run(
            table.insert(
                effectIdColumn <- Int64(id),
                effectNameColumn <- data["name"] as! String,
                effectCategoryColumn <- effectCategory,
                modifierInfoColumn <- modifierInfo
            )
        )
    }
    
}
