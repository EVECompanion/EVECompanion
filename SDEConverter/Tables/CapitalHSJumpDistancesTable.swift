
//
//  CapitalHSJumpDistancesTable.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 16.10.25.
//

import Foundation
import SQLite

class CapitalHSJumpDistancesTable: CapitalJumpDistancesTable {
    
    init() {
        super.init(tableName: "mapCapitalHSJumpDistances")
    }
    
}
