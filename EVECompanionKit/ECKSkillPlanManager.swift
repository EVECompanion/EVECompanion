//
//  ECKSkillPlanManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 30.11.25.
//

import Foundation
public import Combine

public class ECKSkillPlanManager: ObservableObject, Hashable {
    
    @NestedObservableObject public var character: ECKCharacter
    
    @Published public var skillPlans: [ECKSkillPlan] = []
    
    public var currentSkills: ECKCharacterSkills? {
        return character.skills
    }
    
    public init(character: ECKCharacter, isPreview: Bool = false) {
        self.character = character
        Task {
            await loadSkillPlans()
        }
    }
    
    @MainActor
    public func loadSkillPlans() async {
        do {
            let skillPlansDir = try getSkillPlansDir()
            let skillPlansURLs = try FileManager.default.contentsOfDirectory(at: skillPlansDir,
                                                                             includingPropertiesForKeys: nil)
            
            var skillPlans: [ECKSkillPlan] = []
            let decoder = JSONDecoder()
            
            for skillPlanURL in skillPlansURLs {
                do {
                    let skillPlanData = try Data(contentsOf: skillPlanURL)
                    let skillPlan = try decoder.decode(ECKSkillPlan.self, from: skillPlanData)
                    skillPlans.append(skillPlan)
                } catch {
                    logger.error("Cannot load skillPlan: \(error)")
                    continue
                }
            }
            
            self.skillPlans = skillPlans
        } catch {
            logger.error("Error loading skillPlans: \(error)")
            return
        }
    }
    
    private func getDocumentsDirectory() throws -> URL {
        return try FileManager.default.url(for: .documentDirectory,
                                           in: .userDomainMask,
                                           appropriateFor: nil,
                                           create: true)
    }
    
    private func getSkillPlansDir() throws -> URL {
        let documentsDir = try getDocumentsDirectory()
        let skillPlansDir = documentsDir.appendingPathComponent("skillPlans/\(character.id)", isDirectory: true)
        
        if FileManager.default.fileExists(atPath: skillPlansDir.path) == false {
            try FileManager.default.createDirectory(at: skillPlansDir, withIntermediateDirectories: true)
        }
        
        return skillPlansDir
    }
    
    private func getSkillPlanFileURL(_ skillPlan: ECKSkillPlan) throws -> URL {
        let skillPlansDirectoryUrl = try getSkillPlansDir()
        return skillPlansDirectoryUrl.appendingPathComponent("\(skillPlan.id.uuidString).json", isDirectory: false)
    }
    
    @MainActor
    public func createSkillPlan() -> ECKSkillPlan {
        let newPlan = ECKSkillPlan()
        self.skillPlans.append(newPlan)
        self.saveSkillPlan(newPlan)
        return newPlan
    }
    
    public func saveSkillPlan(_ skillPlan: ECKSkillPlan) {
        do {
            let skillPlanURL = try getSkillPlanFileURL(skillPlan)
            let data = try JSONEncoder().encode(skillPlan)
            try data.write(to: skillPlanURL, options: .atomic)
        } catch {
            logger.error("Error saving fitting: \(error)")
        }
    }
    
    public func deleteSkillPlan(_ skillPlanToRemove: ECKSkillPlan) {
        do {
            let skillPlanFileURL = try getSkillPlanFileURL(skillPlanToRemove)
            try FileManager.default.removeItem(at: skillPlanFileURL)
        } catch {
            logger.error("Error deleting skill plan: \(error)")
        }
        
        self.skillPlans.removeAll { plan in
            return plan.id == skillPlanToRemove.id
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(character.id)
    }
    
    public static func == (lhs: ECKSkillPlanManager, rhs: ECKSkillPlanManager) -> Bool {
        return lhs.character == rhs.character
    }
    
}
