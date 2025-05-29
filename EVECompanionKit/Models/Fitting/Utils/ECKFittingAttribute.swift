//
//  ECKFittingAttribute.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 26.05.25.
//

import Foundation

public class ECKFittingAttribute {
    
    let baseValue: Float
    let value: Float?
    var effects: [ECKFittingEffect]
    
    init(value: Float) {
        self.baseValue = value
        self.value = nil
        self.effects = []
    }
    
}
