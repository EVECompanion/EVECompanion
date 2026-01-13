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
        let moveFromoOffsets: IndexSet
        let moveToOffset: Int
        let expectedEntries: [ECKSkillPlanEntry]
    }
    
    static var testCases: [TestCase] = [
        .init(description: "Cannot drop skill after the next level of that skill.",
              initialEntries: [
                .remap(nil),
                .skill(.init(skill: .amarrTitan, level: 1)),
                .skill(.init(skill: .amarrTitan, level: 2))
              ],
              moveFromoOffsets: .init(integer: 1),
              moveToOffset: 3,
              expectedEntries: [
                .remap(nil),
                .skill(.init(skill: .amarrTitan, level: 1)),
                .skill(.init(skill: .amarrTitan, level: 2))
              ]),
        .init(description: "Cannot drop skill after the next level of that skill.",
              initialEntries: [
                .remap(nil),
                .skill(.init(skill: .amarrTitan, level: 2)),
                .skill(.init(skill: .amarrTitan, level: 3))
              ],
              moveFromoOffsets: .init(integer: 1),
              moveToOffset: 3,
              expectedEntries: [
                .remap(nil),
                .skill(.init(skill: .amarrTitan, level: 2)),
                .skill(.init(skill: .amarrTitan, level: 3))
              ]),
        .init(description: "Cannot move skill before the previous level of that skill.",
              initialEntries: [
                .remap(nil),
                .skill(.init(skill: .amarrTitan, level: 1)),
                .skill(.init(skill: .amarrTitan, level: 2))
              ],
              moveFromoOffsets: .init(integer: 2),
              moveToOffset: 1,
              expectedEntries: [
                .remap(nil),
                .skill(.init(skill: .amarrTitan, level: 1)),
                .skill(.init(skill: .amarrTitan, level: 2))
              ]),
        .init(description: "Cannot move skill before the previous level of that skill.",
              initialEntries: [
                .remap(nil),
                .skill(.init(skill: .amarrTitan, level: 2)),
                .skill(.init(skill: .amarrTitan, level: 3))
              ],
              moveFromoOffsets: .init(integer: 2),
              moveToOffset: 1,
              expectedEntries: [
                .remap(nil),
                .skill(.init(skill: .amarrTitan, level: 2)),
                .skill(.init(skill: .amarrTitan, level: 3))
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
    func performReorderingTest(for testCase: TestCase) {
        let skillPlan = ECKSkillPlan(id: UUID(),
                                     name: "",
                                     entries: testCase.initialEntries)
        
        skillPlan.move(fromOffsets: testCase.moveFromoOffsets,
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
