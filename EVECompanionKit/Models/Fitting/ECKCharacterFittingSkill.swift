//
//  ECKCharacterFittingSkill.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.05.25.
//

import Foundation

public class ECKCharacterFittingSkill {
    
    internal let skill: ECKSDEManager.FetchedSkill
    internal let skillItem: ECKItem
    internal var attributes: [ECKCharacterFitting.AttributeID: ECKCharacterFitting.FittingAttribute] = [:]
    
    init(skill: ECKSDEManager.FetchedSkill) {
        self.skill = skill
        self.skillItem = ECKItem(typeId: skill.skillId)
        self.attributes = [:]
    }
    
}
