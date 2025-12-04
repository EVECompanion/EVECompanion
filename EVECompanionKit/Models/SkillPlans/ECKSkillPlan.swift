//
//  ECKSkillPlan.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 30.11.25.
//

import Foundation

public class ECKSkillPlan: Identifiable, Codable, ObservableObject, Hashable {
    
    // MARK: - CodingKeys
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case entries
    }
    
    // MARK: - Demo Data
    
    public static let dummy: ECKSkillPlan = {
        return .init(id: .init(),
                     name: "Demo Skill Plan",
                     entries: [
                        .skill(skill: .init(typeId: 3347), level: 1),
                        .skill(skill: .init(typeId: 3347), level: 2),
                        .skill(skill: .init(typeId: 3347), level: 3),
                        .skill(skill: .init(typeId: 3347), level: 4),
                        .skill(skill: .init(typeId: 3347), level: 5)
                     ])
    }()
    
    // MARK: - Properties
    
    public let id: UUID
    @Published public private(set) var name: String
    
    @Published public private(set) var entries: [ECKSkillPlanEntry]
    
    // MARK: - Initializer
    
    init() {
        self.id = UUID()
        self.name = "New Skill Plan"
        self.entries = []
    }
    
    init(id: UUID, name: String, entries: [ECKSkillPlanEntry]) {
        self.id = id
        self.name = name
        self.entries = entries
    }
    
    // MARK: - Decoder
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.entries = try container.decode([ECKSkillPlanEntry].self, forKey: .entries)
    }
    
    // MARK: - Change Name
    
    public func setName(_ newName: String, manager: ECKSkillPlanManager) {
        self.name = newName
        manager.saveSkillPlan(self)
    }
    
    // MARK: - Add Entry
    
    public func addItem(_ item: ECKItem, manager: ECKSkillPlanManager) {
        guard let currentSkills = manager.character.skills else {
            logger.error("Character skills are not set.")
            return
        }
        
        if item.itemCategory.categoryId == 16 {
            // This item is a skill
            for level in 1...5 {
                if currentSkills.isTrained(skillId: item.typeId, level: level) == false
                    && contains(skillId: item.typeId, level: level) == false {
                    addSkill(item, level: level, currentSkills: currentSkills)
                    return
                }
            }
        } else {
            for skillRequirement in item.skillRequirements ?? [] {
                addSkill(skillRequirement.skill, level: skillRequirement.requiredLevel, currentSkills: currentSkills)
            }
        }
        
        manager.saveSkillPlan(self)
    }
    
    public func addRemapPoint(manager: ECKSkillPlanManager) {
        entries.append(.remap(nil))
        manager.saveSkillPlan(self)
    }
    
    public func addSkill(_ skill: ECKItem, level: Int, manager: ECKSkillPlanManager) {
        guard let currentSkills = manager.currentSkills else {
            logger.error("Character skills are not set.")
            return
        }
        
        addSkill(skill, level: level, currentSkills: currentSkills)
        manager.saveSkillPlan(self)
    }
    
    private func addSkill(_ skill: ECKItem, level: Int, currentSkills: ECKCharacterSkills) {
        let requirements = skill.skillRequirements ?? []
        
        guard level <= 5 && level > 0 else {
            return
        }
        
        guard currentSkills.isTrained(skillId: skill.id, level: level) == false else {
            return
        }
        
        // First: Ensure that all requirements are trained
        for requirement in requirements {
            // Check if the requirement is trained
            // swiftlint:disable:next for_where
            if currentSkills.isTrained(skillId: requirement.skill.id, level: requirement.requiredLevel) == false {
                // The requirement is NOT trained, check if it is already planned
                if self.contains(skillId: requirement.skill.id, level: requirement.requiredLevel) == false {
                    addSkill(requirement.skill, level: requirement.requiredLevel, currentSkills: currentSkills)
                }
            }
        }
        
        // Second: Ensure that all previous levels were trained
        // Get all entries which contain this skill
        let maximumExistingSkillEntry = entries.filter({ entry in
            switch entry {
            case .remap:
                return false
            case .skill(skill: let existingSkill, level: _):
                return existingSkill.id == skill.id
            }
        }).compactMap({ $0.level }).max() ?? 0
        
        guard maximumExistingSkillEntry < level else {
            return
        }
        
        for level in (maximumExistingSkillEntry + 1)...level {
            guard currentSkills.isTrained(skillId: skill.id, level: level) == false else {
                continue
            }
            
            entries.append(.skill(skill: skill, level: level))
        }
    }
    
    // MARK: - Remove
    
    public func remove(_ indices: IndexSet, manager: ECKSkillPlanManager) {
        guard let indexToRemove = indices.first else {
            return
        }
        
        let entry = entries[indexToRemove]
        
        switch entry {
        case .remap:
            entries.remove(at: indexToRemove)
        case .skill(skill: let skill, level: let level):
            self.remove(skill, level: level)
        }
        
        manager.saveSkillPlan(self)
    }
    
    private func remove(_ skill: ECKItem, level: Int) {
        let newEntries = removeSkill(skill.id, level: level, from: entries)
        self.entries = newEntries
    }
    
    private func removeSkill(_ skillId: Int, level: Int, from entries: [ECKSkillPlanEntry]) -> [ECKSkillPlanEntry] {
        // First: Remove this skill from the list
        var result = entries.filter { entry in
            switch entry {
            case .remap:
                return true
            case .skill(skill: let skill, level: let existingLevel):
                return (skill.id == skillId && existingLevel == level) == false
            }
        }
        
        // Second: Remove all entries which are the same skill but with a higher level than the skill to remove.
        if level < 5 {
            for level in (level + 1)...5 {
                result = removeSkill(skillId, level: level, from: result)
            }
        }
        
        // Third: Remove all skills which no longer meet their requirements.
        for entryToCheck in result {
            switch entryToCheck {
            case .remap:
                continue
            case .skill(let skill, let level):
                let requirements = skill.skillRequirements ?? []
                
                for requirement in requirements {
                    if requirement.skill.id == skillId && requirement.requiredLevel >= level {
                        result = removeSkill(skill.id, level: level, from: result)
                    }
                }
            }
        }
        
        return result
    }
    
    // MARK: - Utils
    
    public func contains(skillId: Int, level: Int) -> Bool {
        return entries.contains(where: { entry in
            switch entry {
            case .remap:
                return false
            case .skill(let skill, let skillLevel):
                return skill.id == skillId && skillLevel == level
            }
        })
    }
    
    // MARK: - Encoder
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(entries, forKey: .entries)
    }
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(entries)
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: ECKSkillPlan, rhs: ECKSkillPlan) -> Bool {
        return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.entries == rhs.entries
    }
    
}
