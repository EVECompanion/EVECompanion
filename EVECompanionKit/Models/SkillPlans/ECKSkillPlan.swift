//
//  ECKSkillPlan.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 30.11.25.
//

import Foundation

public class ECKSkillPlan: Identifiable, Codable, ObservableObject, Hashable {
    
    // MARK: - Constants
    
    static private let maxRemappablePointsPerAttribute: Int = 10
    static private let spareAttributePointsOnRemap: Int = 14
    
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
                        .skill(.init(skill: .init(typeId: 3347), level: 1)),
                        .skill(.init(skill: .init(typeId: 3347), level: 2)),
                        .skill(.init(skill: .init(typeId: 3347), level: 3)),
                        .skill(.init(skill: .init(typeId: 3347), level: 4)),
                        .skill(.init(skill: .init(typeId: 3347), level: 5))
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
        
        defer {
            self.recalculateRemapPoints()
            manager.saveSkillPlan(self)
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
        self.recalculateRemapPoints()
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
            case .skill(let existingEntry):
                return existingEntry.skill.id == skill.id
            }
        }).compactMap({ $0.level }).max() ?? 0
        
        guard maximumExistingSkillEntry < level else {
            return
        }
        
        for level in (maximumExistingSkillEntry + 1)...level {
            guard currentSkills.isTrained(skillId: skill.id, level: level) == false else {
                continue
            }
            
            entries.append(.skill(.init(skill: skill, level: level)))
        }
    }
    
    // MARK: - Move
    
    public func move(fromOffsets: IndexSet, toOffset: Int, manager: ECKSkillPlanManager) {
        guard fromOffsets.contains(toOffset) == false else {
            return
        }
        
        guard let currentSkills = manager.currentSkills else {
            return
        }
        
        entries.move(fromOffsets: fromOffsets, toOffset: toOffset)
        fixSkillOrder(currentSkills: currentSkills)
        recalculateRemapPoints()
        manager.saveSkillPlan(self)
    }
    
    private func fixSkillOrder(currentSkills: ECKCharacterSkills) {
        var requirements: [ECKSkillPlanSkillEntry: [ECKItem.SkillRequirement]] = [:]
        
        var entries = self.entries
        var newEntries: [ECKSkillPlanEntry] = []
        
        for entry in entries {
            if let skill = entry.skill {
                if skill.level == 1 {
                    requirements[skill] = skill.skill.skillRequirements
                } else {
                    requirements[skill] = [.init(skill: skill.skill, requiredLevel: skill.level - 1)]
                }
            }
        }
        
        while entries.isEmpty == false {
            guard let entryToAdd = entries.enumerated().first(where: { dependencies(for: $0.element, currentSkills: currentSkills, currentEntries: newEntries).isEmpty }) else {
                // TODO
                break
            }
            
            newEntries.append(entryToAdd.element)
            entries = entries.enumerated().filter({ $0 != entryToAdd }).map({ $0.element })
        }
        
        self.entries = newEntries
    }
    
    private func dependencies(for entry: ECKSkillPlanEntry, currentSkills: ECKCharacterSkills, currentEntries: [ECKSkillPlanEntry]) -> [ECKSkillPlanEntry] {
        let currentEntriesContain: (ECKSkillPlanSkillEntry) -> Bool = { entryToCheck in
            return currentEntries.contains(where: { entry in
                switch entry {
                case .remap:
                    return false
                case .skill(let entry):
                    return entry.skill.id == entryToCheck.skill.id && entry.level == entryToCheck.level
                }
            })
        }
        
        guard let skill = entry.skill else {
            return []
        }
        
        guard skill.level <= 1 else {
            let requirement: ECKSkillPlanSkillEntry = .init(skill: skill.skill, level: skill.level - 1)
            
            if currentEntriesContain(requirement) || currentSkills.isTrained(skillId: requirement.skill.id, level: requirement.level) {
                return []
            } else {
                return [.skill(requirement)]
            }
        }
        
        guard let requirements = skill.skill.skillRequirements, requirements.isEmpty == false else {
            return []
        }
        
        var requirementEntries: [ECKSkillPlanSkillEntry] = []
        
        for requirement in requirements {
            let requirementEntry: ECKSkillPlanSkillEntry = .init(skill: requirement.skill, level: requirement.requiredLevel)
            
            if currentEntriesContain(requirementEntry) == false && currentSkills.isTrained(skillId: requirement.skill.id, level: requirement.requiredLevel) == false {
                requirementEntries.append(.init(skill: requirement.skill, level: requirement.requiredLevel))
            }
        }
        
        return requirementEntries.map({ .skill($0) })
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
        case .skill(let entry):
            self.remove(entry.skill, level: entry.level)
        }
        
        self.recalculateRemapPoints()
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
            case .skill(let existingEntry):
                return (existingEntry.skill.id == skillId && existingEntry.level == level) == false
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
            case .skill(let entry):
                let requirements = entry.skill.skillRequirements ?? []
                
                for requirement in requirements {
                    if requirement.skill.id == skillId && requirement.requiredLevel >= entry.level {
                        result = removeSkill(entry.skill.id, level: entry.level, from: result)
                    }
                }
            }
        }
        
        return result
    }
    
    // MARK: - Attribute Calculation
    
    private func recalculateRemapPoints() {
        clearRemapPoints()
        
        let remapPoints = entries.filter { entry in
            return entry.isRemapPoint
        }
        var chunks: [[ECKSkillPlanSkillEntry]] = []
        
        if remapPoints.isEmpty {
            chunks.append(self.entries.compactMap({ entry in
                switch entry {
                case .remap:
                    return nil
                case .skill(let skill):
                    return skill
                }
            }))
        } else {
            var currentChunkEntries: [ECKSkillPlanSkillEntry] = []
            
            for entry in entries.enumerated() {
                if entry.element.isSkillEntry {
                    if case .skill(let skill) = entry.element {
                        currentChunkEntries.append(skill)
                    }
                } else if entry.offset > 0 {
                    chunks.append(currentChunkEntries)
                    currentChunkEntries = []
                }
            }
            
            chunks.append(currentChunkEntries)
        }
        
        var newEntries: [ECKSkillPlanEntry] = []
        for chunk in chunks {
            guard chunk.isEmpty == false else {
                newEntries.append(.remap(nil))
                continue
            }
            
            let optimizedChunk = optimizeChunk(chunk)
            newEntries.append(contentsOf: optimizedChunk)
        }
        
        self.entries = newEntries
    }
    
    private func optimizeChunk(_ chunk: [ECKSkillPlanSkillEntry]) -> [ECKSkillPlanEntry] {
        var bestRemap = ECKSkillPlanRemap(charisma: 0, intelligence: 0, memory: 0, perception: 0, willpower: 0)
        var bestTime: TimeInterval = .greatestFiniteMagnitude
        
        for perception in 0...Self.maxRemappablePointsPerAttribute {
            let maxWillpower = Self.spareAttributePointsOnRemap - perception
            
            for willpower in 0...min(maxWillpower, Self.maxRemappablePointsPerAttribute) {
                let maxIntelligence = maxWillpower - willpower
                
                for intelligence in 0...min(maxIntelligence, Self.maxRemappablePointsPerAttribute) {
                    let maxMemory = maxIntelligence - intelligence
                    
                    for memory in 0...min(maxMemory, Self.maxRemappablePointsPerAttribute) {
                        let charisma = maxMemory - memory
                        
                        guard charisma <= Self.maxRemappablePointsPerAttribute else {
                            continue
                        }
                        
                        let remap = ECKSkillPlanRemap(charisma: charisma,
                                                      intelligence: intelligence,
                                                      memory: memory,
                                                      perception: perception,
                                                      willpower: willpower)
                        
                        var totalTrainingTime: TimeInterval = 0
                        for entry in chunk {
                            totalTrainingTime += entry.skill.skillTime(for: remap, skillLevel: entry.level)
                        }
                        
                        if totalTrainingTime < bestTime {
                            bestTime = totalTrainingTime
                            bestRemap = remap
                        }
                    }
                }
            }
        }
        
        var result: [ECKSkillPlanEntry] = []
        result.append(.remap(bestRemap))
        result.append(contentsOf: chunk.map({ .skill($0) }))
        return result
    }
    
    private func clearRemapPoints() {
        self.entries = self.entries.map({ entry in
            switch entry {
            case .remap:
                return .remap(nil)
            case .skill(let entry):
                return .skill(entry)
            }
        })
    }
    
    // MARK: - Utils
    
    public func contains(skillId: Int, level: Int) -> Bool {
        return entries.contains(where: { entry in
            switch entry {
            case .remap:
                return false
            case .skill(let entry):
                return entry.skill.id == skillId && entry.level == level
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
