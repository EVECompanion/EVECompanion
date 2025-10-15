//
//  TraitsTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 15.10.25.
//

import Foundation
import SQLite

class TraitsTable: SDETable {
    
    var table: SQLite.Table = .init("invTraits")
    
    private let traitIdColumn = Expression<Int64>("traitID")
    private let typeIdColumn = Expression<Int64>("typeID")
    private let bonusColumn = Expression<Float64?>("bonus")
    private let bonusTextColumn = Expression<String>("bonusText")
    private let skillIdColumn = Expression<Int64>("skillID")
    private let unitIdColumn = Expression<Int64?>("unitID")
    
    func addColumns(to table: SQLite.TableBuilder) {
        table.column(traitIdColumn, primaryKey: .autoincrement)
        table.column(typeIdColumn)
        table.column(bonusColumn)
        table.column(bonusTextColumn)
        table.column(skillIdColumn)
        table.column(unitIdColumn)
    }
    
    func add(id: Int, data: [String : Any], to db: SQLite.Connection) throws {
        let typeId = id
        
        let roleBonuses: [[String: Any]] = (data["roleBonuses"] as? [[String: Any]]) ?? []
        
        for roleBonus in roleBonuses {
            let bonusInt = roleBonus["bonus"] as? Int
            let bonusDouble = roleBonus["bonus"] as? Double
            let bonus: Double?
            if let bonusInt {
                bonus = Double(bonusInt)
            } else {
                bonus = bonusDouble
            }
            
            let unitId = roleBonus["unitID"] as? Int
            
            try db.run(
                table.insert(
                    typeIdColumn <- Int64(typeId),
                    bonusColumn <- bonus != nil ? Float64(bonus!) : nil,
                    bonusTextColumn <- (roleBonus["bonusText"] as! [String: Any])["en"] as! String,
                    skillIdColumn <- -1,
                    unitIdColumn <- unitId != nil ? Int64(unitId!) : nil
                )
            )
        }
        
        let skillBonuses: [String: Any] = (data["types"] as? [String: Any]) ?? [:]
        
        for skillBonus in skillBonuses {
            let bonuses = skillBonus.value as! [[String: Any]]
            
            for bonusDict in bonuses {
                let skillId = Int(skillBonus.key)!
                let bonusInt = bonusDict["bonus"] as? Int
                let bonusDouble = bonusDict["bonus"] as? Double
                let bonus: Double?
                if let bonusInt {
                    bonus = Double(bonusInt)
                } else {
                    bonus = bonusDouble
                }
                
                let unitId = bonusDict["unitID"] as? Int
                
                try db.run(
                    table.insert(
                        typeIdColumn <- Int64(typeId),
                        bonusColumn <- bonus != nil ? Float64(bonus!) : nil,
                        bonusTextColumn <- (bonusDict["bonusText"] as! [String: Any])["en"] as! String,
                        skillIdColumn <- Int64(skillId),
                        unitIdColumn <- unitId != nil ? Int64(unitId!) : nil
                    )
                )
            }
        }
        
        let miscBonuses: [[String: Any]] = (data["miscBonuses"] as? [[String: Any]]) ?? []
        
        for bonusDict in miscBonuses {
            let bonusInt = bonusDict["bonus"] as? Int
            let bonusDouble = bonusDict["bonus"] as? Double
            let bonus: Double?
            if let bonusInt {
                bonus = Double(bonusInt)
            } else {
                bonus = bonusDouble
            }
            
            let unitId = bonusDict["unitID"] as? Int
            
            try db.run(
                table.insert(
                    typeIdColumn <- Int64(typeId),
                    bonusColumn <- bonus != nil ? Float64(bonus!) : nil,
                    bonusTextColumn <- (bonusDict["bonusText"] as! [String: Any])["en"] as! String,
                    skillIdColumn <- -2,
                    unitIdColumn <- unitId != nil ? Int64(unitId!) : nil
                )
            )
        }
    }
    
}
