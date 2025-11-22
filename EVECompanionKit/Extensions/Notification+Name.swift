//
//  Notification+Name.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.05.24.
//

import Foundation

extension Notification.Name {
    
    static let tokensDidChange = Notification.Name("TokensDidChange")
    static let sdeUpdated = Notification.Name("SDEUpdated")
    static let sdeDeleted = Notification.Name("SDEDeleted")
    static let pushPermissionGranted = Notification.Name("PushPermissionGranted")
}
