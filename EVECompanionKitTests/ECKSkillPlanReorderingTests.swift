//
//  ECKSkillPlanReorderingTests.swift
//  EVECompanionKitTests
//
//  Created by Jonas Schlabertz on 10.01.26.
//

import Testing
@testable import EVECompanionKit

struct ECKSkillPlanReorderingTests {

    struct TestCase {
        let description: Comment
        let initialEntries: [ECKSkillPlanEntry]
        let moveFromOffsets: IndexSet
        let moveToOffset: Int
        let expectedEntries: [ECKSkillPlanEntry]
    }
    
    static var testCases: [TestCase] = [
        .init(description: "Cannot drop skill after the next level of that skill.",
              initialEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1)),
                .skill(.init(skill: .missileLauncherOperation, level: 2))
              ],
              moveFromOffsets: .init(integer: 1),
              moveToOffset: 3,
              expectedEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1)),
                .skill(.init(skill: .missileLauncherOperation, level: 2))
              ]),
        .init(description: "Cannot drop skill after the next level of that skill.",
              initialEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1)),
                .skill(.init(skill: .missileLauncherOperation, level: 2)),
                .skill(.init(skill: .missileLauncherOperation, level: 3))
              ],
              moveFromOffsets: .init(integer: 2),
              moveToOffset: 4,
              expectedEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1)),
                .skill(.init(skill: .missileLauncherOperation, level: 2)),
                .skill(.init(skill: .missileLauncherOperation, level: 3))
              ]),
        .init(description: "Cannot move skill before the previous level of that skill.",
              initialEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1)),
                .skill(.init(skill: .missileLauncherOperation, level: 2))
              ],
              moveFromOffsets: .init(integer: 2),
              moveToOffset: 1,
              expectedEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1)),
                .skill(.init(skill: .missileLauncherOperation, level: 2))
              ]),
        .init(description: "Cannot move skill before the previous level of that skill.",
              initialEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1)),
                .skill(.init(skill: .missileLauncherOperation, level: 2)),
                .skill(.init(skill: .missileLauncherOperation, level: 3))
              ],
              moveFromOffsets: .init(integer: 3),
              moveToOffset: 2,
              expectedEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1)),
                .skill(.init(skill: .missileLauncherOperation, level: 2)),
                .skill(.init(skill: .missileLauncherOperation, level: 3))
              ]),
        .init(description: "Cannot move skill before a requirement of that skill.",
              initialEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1)),
                .skill(.init(skill: .missileLauncherOperation, level: 2)),
                .skill(.init(skill: .lightMissiles, level: 1))
              ],
              moveFromOffsets: .init(integer: 3),
              moveToOffset: 2,
              expectedEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1)),
                .skill(.init(skill: .missileLauncherOperation, level: 2)),
                .skill(.init(skill: .lightMissiles, level: 1))
              ]),
        .init(description: "Cannot move skill after a skill that requires that skill.",
              initialEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1)),
                .skill(.init(skill: .missileLauncherOperation, level: 2)),
                .skill(.init(skill: .lightMissiles, level: 1))
              ],
              moveFromOffsets: .init(integer: 2),
              moveToOffset: 4,
              expectedEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1)),
                .skill(.init(skill: .missileLauncherOperation, level: 2)),
                .skill(.init(skill: .lightMissiles, level: 1))
              ]),
        .init(description: "Does not delete remap points when dropping them on themselves.",
              initialEntries: [
                .remap(nil)
              ],
              moveFromOffsets: .init(integer: 0),
              moveToOffset: 0,
              expectedEntries: [
                .remap(nil)
              ]),
        .init(description: "Does not delete remap points when dropping them on themselves.",
              initialEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1))
              ],
              moveFromOffsets: .init(integer: 0),
              moveToOffset: 0,
              expectedEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1))
              ]),
        .init(description: "Cannot move skills after a skill that requires it recursively.",
              initialEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1)),
                .skill(.init(skill: .missileLauncherOperation, level: 2)),
                .skill(.init(skill: .missileLauncherOperation, level: 3)),
                .skill(.init(skill: .lightMissiles, level: 1)),
                .skill(.init(skill: .lightMissiles, level: 2)),
                .skill(.init(skill: .lightMissiles, level: 3)),
                .skill(.init(skill: .heavyMissiles, level: 1))
              ],
              moveFromOffsets: .init(integer: 1),
              moveToOffset: 8,
              expectedEntries: [
                .remap(nil),
                .skill(.init(skill: .missileLauncherOperation, level: 1)),
                .skill(.init(skill: .missileLauncherOperation, level: 2)),
                .skill(.init(skill: .missileLauncherOperation, level: 3)),
                .skill(.init(skill: .lightMissiles, level: 1)),
                .skill(.init(skill: .lightMissiles, level: 2)),
                .skill(.init(skill: .lightMissiles, level: 3)),
                .skill(.init(skill: .heavyMissiles, level: 1))
              ])
    ]
    
    class DummySkillPlanManager: ECKSkillPlanManager {
        init() {
            super.init(character: .dummy, isPreview: true)
        }
        
        override func createSkillPlan() -> ECKSkillPlan {
            fatalError("Not implemented")
        }
        
        override func saveSkillPlan(_ skillPlan: ECKSkillPlan) {
            return
        }
        
        override func deleteSkillPlan(_ skillPlanToRemove: ECKSkillPlan) {
            return
        }
        
        override func loadSkillPlans() async {
            return
        }
    }
    
    let skillPlanManager = DummySkillPlanManager()
    
    @Test(arguments: testCases)
    func runSkillPlanReorderingTests(for testCase: TestCase) {
        let skillPlan = ECKSkillPlan(id: UUID(),
                                     name: "",
                                     entries: testCase.initialEntries)
        
        skillPlan.move(fromOffsets: testCase.moveFromOffsets,
                       toOffset: testCase.moveToOffset,
                       manager: skillPlanManager)
        
        #expect(skillPlan.entries.count == testCase.expectedEntries.count, testCase.description)
        
        for elements in zip(skillPlan.entries, testCase.expectedEntries) {
            #expect(elements.0.isRemapPoint == elements.1.isRemapPoint)
            
            switch (elements.0, elements.1) {
            case (.skill(let lhsEntry), .skill(let rhsEntry)):
                #expect(lhsEntry == rhsEntry, testCase.description)
            default:
                continue
            }
        }
    }
    
}
