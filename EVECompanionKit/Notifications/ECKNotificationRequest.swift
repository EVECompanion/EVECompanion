//
//  ECKNotificationRequest.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 03.05.25.
//

import UserNotifications

protocol ECKNotificationRequest {
    var request: UNNotificationRequest? { get }
}
