//
//  ECKMapGestureRecognitionPolicyTests.swift
//  EVECompanionKitTests
//
//  Created by Jonas Schlabertz on 30.06.26.
//

import Testing
import UIKit
@testable import EVECompanionKit

struct ECKMapGestureRecognitionPolicyTests {

    @Test
    @MainActor
    func allowsMapPanAndPinchToRecognizeSimultaneously() {
        let panRecognizer = UIPanGestureRecognizer()
        let pinchRecognizer = UIPinchGestureRecognizer()

        #expect(ECKMapGestureRecognitionPolicy.shouldRecognizeSimultaneously(panRecognizer, with: pinchRecognizer))
        #expect(ECKMapGestureRecognitionPolicy.shouldRecognizeSimultaneously(pinchRecognizer, with: panRecognizer))
    }

    @Test
    @MainActor
    func keepsTapGesturesExclusiveFromMapPanAndPinch() {
        let tapRecognizer = UITapGestureRecognizer()
        let panRecognizer = UIPanGestureRecognizer()
        let pinchRecognizer = UIPinchGestureRecognizer()

        #expect(ECKMapGestureRecognitionPolicy.shouldRecognizeSimultaneously(tapRecognizer, with: panRecognizer) == false)
        #expect(ECKMapGestureRecognitionPolicy.shouldRecognizeSimultaneously(tapRecognizer, with: pinchRecognizer) == false)
    }

}
