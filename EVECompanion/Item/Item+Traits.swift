//
//  Item+Traits.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 05.04.25.
//

import EVECompanionKit

extension ECKItem {
    
    var bonusTexts: [(header: AttributedString, text: AttributedString)] {
        var result: [(header: AttributedString, text: AttributedString)] = []
        
        for trait in itemTraits {
            let header: String
            if let skill = trait.skillName,
               let skillId = trait.skillId,
               skill.isEmpty == false {
                header = "<a href=\"showInfo:\(skillId)\"><b>\(skill)</b></a> bonuses (per skill level)"
            } else {
                header = "Role Bonuses"
            }
            
            var text: String = "• "
            for entry in trait.entries {
                if text != "• " {
                    text.append("<br/> • ")
                }
                
                if let bonus = entry.bonus {
                    var bonusText: String = ""
                    
                    if let unit = entry.unit {
                        bonusText.append(unit.formatted(Float(bonus)))
                    } else {
                        bonusText.append(ECFormatters.attributeValue(Float(bonus)))
                    }
                    
                    text.append("\(bonusText) ")
                }
                text.append(entry.bonusText)
            }
            
            result.append((header: header.convertToAttributed(),
                           text: text.convertToAttributed()))
        }
        
        return result
    }
    
}
