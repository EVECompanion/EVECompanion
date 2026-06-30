//
//  ECKMapGestureRecognitionPolicy.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 30.06.26.
//

public import UIKit

public enum ECKMapGestureRecognitionPolicy {

    public static func shouldRecognizeSimultaneously(_ gestureRecognizer: UIGestureRecognizer,
                                                     with otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return isPanPinchPair(gestureRecognizer, otherGestureRecognizer)
    }

    private static func isPanPinchPair(_ gestureRecognizer: UIGestureRecognizer,
                                       _ otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return (gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer)
            || (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer)
    }

}
