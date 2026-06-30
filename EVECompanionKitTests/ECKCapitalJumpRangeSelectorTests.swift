//
//  ECKCapitalJumpRangeSelectorTests.swift
//  EVECompanionKitTests
//
//  Created by Jonas Schlabertz on 30.06.26.
//

import Foundation
import Testing
@testable import EVECompanionKit

struct ECKCapitalJumpRangeSelectorTests {

    @Test
    func returnsSystemsAtOrBelowJumpRangeForMapSelection() {
        let jumpDistances = [
            1: [
                2: 4.5,
                3: 5.0,
                4: 5.1
            ]
        ]

        let systemIds = ECKCapitalJumpRangeSelector.systemIdsInRange(from: 1,
                                                                     jumpDistances: jumpDistances,
                                                                     jumpRange: 5.0)

        #expect(systemIds == [2, 3])
    }

    @Test
    func excludesUnavailableSystemsFromMapSelection() {
        let jumpDistances = [
            1: [
                2: 4.5,
                3: 5.0,
                4: 9.0
            ]
        ]

        let systemIds = ECKCapitalJumpRangeSelector.systemIdsInRange(from: 1,
                                                                     jumpDistances: jumpDistances,
                                                                     jumpRange: 5.0,
                                                                     excluding: [3])

        #expect(systemIds == [2])
    }

}
