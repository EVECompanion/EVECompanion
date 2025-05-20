//
//  ECKNotificationManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 03.05.25.
//

import Foundation
public import UserNotifications
import UIKit

public actor ECKNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    
    private static let maximumNotifications = 64
    private let authorizationOptions: UNAuthorizationOptions = [.alert, .sound]
    private let userNotificationCenter = UNUserNotificationCenter.current()
    
    @MainActor
    public var didGrantPermission: Bool? {
        guard let permissionStatus else {
            return nil
        }
        
        switch permissionStatus {
        case .notDetermined:
            return false
        case .denied:
            return false
        case .authorized:
            return true
        case .provisional:
            return true
        case .ephemeral:
            return true
        @unknown default:
            return nil
        }
    }
    
    @MainActor
    @Published var permissionStatus: UNAuthorizationStatus? {
        didSet {
            if let oldValue,
               permissionStatus != oldValue,
               permissionStatus == .authorized
               || permissionStatus == .ephemeral
               || permissionStatus == .provisional {
                NotificationCenter.default.post(name: .pushPermissionGranted, object: nil)
            }
        }
    }
    
    public static let shared: ECKNotificationManager = .init()
    
    private var isSchedulingNotifications: Bool = false
    
    override private init() {
        super.init()
        Task {
            await refreshPermissionStatus()
        }
    }
    
    @MainActor
    public func refreshPermissionStatus() async {
        permissionStatus = await userNotificationCenter.notificationSettings().authorizationStatus
    }
    
    @MainActor
    public func requestPermission() async throws {
        guard let permissionStatus else {
            return
        }
        
        switch permissionStatus {
        case .authorized,
             .ephemeral,
             .provisional:
            // Already granted, nothing to do here.
            return
        case .denied:
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                logger.error("SettingsURL is nil")
                return
            }
            
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        case .notDetermined:
            do {
                let didGrant = try await userNotificationCenter.requestAuthorization(options: self.authorizationOptions)
                if didGrant {
                    self.permissionStatus = .authorized
                    NotificationCenter.default.post(name: .pushPermissionGranted, object: nil)
                } else {
                    self.permissionStatus = .denied
                }
            } catch {
                logger.error("Error requesting push permission \(error)")
                throw error
            }
        @unknown default:
            logger.warning("Unknown notification status \(permissionStatus)")
        }
    }
    
    private func clearPendingNotificationRequests() {
        userNotificationCenter.removeAllPendingNotificationRequests()
    }
    
    internal func scheduleNotifications(for characters: [ECKCharacter]) async {
        guard isSchedulingNotifications == false else {
            return
        }
        
        isSchedulingNotifications = true
        
        defer {
            isSchedulingNotifications = false
        }
        
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            return
        }
        
        await refreshPermissionStatus()
        guard await didGrantPermission ?? false else {
            logger.error("No push permission granted, aborting.")
            return
        }
        
        clearPendingNotificationRequests()
        
        guard characters.isEmpty == false else {
            return
        }
        
        logger.info("Scheduling notifications.")
        
        if UserDefaults.standard.enableEmptySkillQueueNotifications {
            // First: Schedule notifications for empty skillqueues.
            for character in characters {
                if let skillQueue = character.skillqueue,
                   let finishDate = skillQueue.last?.finishDate {
                    await scheduleNotification(ECKEmptySkillQueueWarningNotificationRequest(character: character,
                                                                                            skillQueueFinishDate: finishDate))
                }
            }
        }
        
        if UserDefaults.standard.enableSkillCompletedNotifications {
            // Second: Schedule notifications for completed skills until the notification limit is reached
            let maxSkillQueueCount: Int = characters.map({ $0.skillqueue?.currentEntries.count ?? 0 }).max() ?? 0
            for i in 0...maxSkillQueueCount {
                for character in characters {
                    guard await canScheduleMoreNotifications() else {
                        return
                    }
                    
                    if let skillQueue = character.skillqueue,
                       skillQueue.currentEntries.indices.contains(i) {
                        let skill = skillQueue.currentEntries[i]
                        let request = ECKSkillCompletedNotificationRequest(character: character, skill: skill)
                        await scheduleNotification(request)
                    }
                }
            }
        }
    }
    
    private func canScheduleMoreNotifications() async -> Bool {
        return await userNotificationCenter.pendingNotificationRequests().count <= Self.maximumNotifications
    }
    
    private func scheduleNotification(_ request: any ECKNotificationRequest) async {
        guard await canScheduleMoreNotifications() else {
            return
        }
        
        guard let request = request.request else {
            return
        }
        
        logger.info("Scheduling notification request \(request)")
        
        do {
            try await userNotificationCenter.add(request)
        } catch {
            logger.error("Unable to add notification request \(request): \(error)")
        }
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.sound, .banner, .list]
    }
    
}
