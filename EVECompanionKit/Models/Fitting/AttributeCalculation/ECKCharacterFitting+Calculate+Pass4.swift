//
//  ECKCharacterFitting+Calculate+Pass4.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.05.25.
//

import Foundation

extension ECKCharacterFitting {
    
    internal func pass4() {
        var cpuUsage: Float = 0
        var pgUsage: Float = 0
        
        for item in self.items {
            let cpuAttribute = item.attributes[Self.attributeCpuUsageId]
            cpuUsage += cpuAttribute?.value ?? cpuAttribute?.baseValue ?? 0
            
            let pgAttribute = item.attributes[Self.attributePowerGridUsageId]
            pgUsage += pgAttribute?.value ?? pgAttribute?.baseValue ?? 0
        }
        
        ship.attributes[Self.attributeCpuLoadId] = .init(id: Self.attributeCpuLoadId,
                                                         defaultValue: cpuUsage)
        ship.attributes[Self.attributeCpuLoadId]?.value = cpuUsage
        
        ship.attributes[Self.attributePowerLoadId] = .init(id: Self.attributePowerLoadId,
                                                           defaultValue: pgUsage)
        ship.attributes[Self.attributePowerLoadId]?.value = pgUsage
    }
    
}
