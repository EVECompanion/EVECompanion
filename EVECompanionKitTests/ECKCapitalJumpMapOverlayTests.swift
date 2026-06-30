//
//  ECKCapitalJumpMapOverlayTests.swift
//  EVECompanionKitTests
//
//  Created by Jonas Schlabertz on 30.06.26.
//

import Foundation
import Testing
@testable import EVECompanionKit

struct ECKCapitalJumpMapOverlayTests {
    
    @Test
    func returnsOrderedRouteSegmentsForMapOverlay() {
        let segments = ECKCapitalJumpMapOverlay.routeSegments(systemIds: [10, 20, 30])

        #expect(segments.count == 2)
        #expect(segments[0].startSystemId == 10)
        #expect(segments[0].destinationSystemId == 20)
        #expect(segments[1].startSystemId == 20)
        #expect(segments[1].destinationSystemId == 30)
    }

    @Test
    func returnsNoRouteSegmentsWhenRouteHasFewerThanTwoSystems() {
        #expect(ECKCapitalJumpMapOverlay.routeSegments(systemIds: []).isEmpty)
        #expect(ECKCapitalJumpMapOverlay.routeSegments(systemIds: [10]).isEmpty)
    }

    @Test
    func returnsAllDrawnRouteSystemsForMapHighlighting() {
        let highlightedSystemIds = ECKCapitalJumpMapOverlay.highlightedRouteSystemIds(systemIds: [10, 20, 30])

        #expect(highlightedSystemIds == Set([10, 20, 30]))
    }

    @Test
    func collapsesRepeatedRouteSystemsForMapHighlighting() {
        let highlightedSystemIds = ECKCapitalJumpMapOverlay.highlightedRouteSystemIds(systemIds: [10, 20, 10])

        #expect(highlightedSystemIds == Set([10, 20]))
    }

    @Test
    func includesReplacementSystemInMapFocusSet() {
        let focusSystemIds = ECKCapitalJumpMapOverlay.focusSystemIds(highlightedSystemIds: [10, 20],
                                                                     replacementSystemId: 30)

        #expect(focusSystemIds == Set([10, 20, 30]))
    }

    @Test
    func keepsMapFocusSetUnchangedWithoutReplacementSystem() {
        let focusSystemIds = ECKCapitalJumpMapOverlay.focusSystemIds(highlightedSystemIds: [10, 20],
                                                                     replacementSystemId: nil)

        #expect(focusSystemIds == Set([10, 20]))
    }

}
