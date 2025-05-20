//
//  UserDefaults+Keys.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 12.05.24.
//

import Foundation

public enum ECKDefaultKeys: String {
    case isDemoModeEnabled = "isDemoModeEnabled"
    case showDatesInUTC = "showDatesInUTC"
    case localSDEVersion = "localSDEVersion"
    
    case didPerformTokenMigration = "didPerformTokenMigration"
    case didDismissPushCTA = "didDismissPushCTA"
    case enableEmptySkillQueueNotifications = "enableEmptySkillQueueNotifications"
    case enableSkillCompletedNotifications = "enableSkillCompletedNotifications"
}

public extension UserDefaults {
    @objc dynamic var isDemoModeEnabled: Bool {
        get { bool(forKey: ECKDefaultKeys.isDemoModeEnabled.rawValue) }
        set { setValue(newValue, forKey: ECKDefaultKeys.isDemoModeEnabled.rawValue) }
    }
    
    @objc dynamic var showDatesInUTC: Bool {
        get { bool(forKey: ECKDefaultKeys.showDatesInUTC.rawValue) }
        set { setValue(newValue, forKey: ECKDefaultKeys.showDatesInUTC.rawValue) }
    }
    
    dynamic var localSDEVersion: Int {
        get { integer(forKey: ECKDefaultKeys.localSDEVersion.rawValue) }
        set { setValue(newValue, forKey: ECKDefaultKeys.localSDEVersion.rawValue) }
    }
    
    dynamic var didPerformTokenMigration: Bool {
        get { bool(forKey: ECKDefaultKeys.didPerformTokenMigration.rawValue) }
        set { setValue(newValue, forKey: ECKDefaultKeys.didPerformTokenMigration.rawValue) }
    }
    
    dynamic var didDismissPushCTA: Bool {
        get { bool(forKey: ECKDefaultKeys.didDismissPushCTA.rawValue) }
        set { setValue(newValue, forKey: ECKDefaultKeys.didDismissPushCTA.rawValue) }
    }
    
    @objc dynamic var enableEmptySkillQueueNotifications: Bool {
        get {
            if value(forKey: ECKDefaultKeys.enableEmptySkillQueueNotifications.rawValue) == nil {
                return true
            }
            
            return bool(forKey: ECKDefaultKeys.enableEmptySkillQueueNotifications.rawValue)
        }
        set {
            setValue(newValue, forKey: ECKDefaultKeys.enableEmptySkillQueueNotifications.rawValue)
        }
    }
    
    @objc dynamic var enableSkillCompletedNotifications: Bool {
        get {
            if value(forKey: ECKDefaultKeys.enableSkillCompletedNotifications.rawValue) == nil {
                return true
            }
            
            return bool(forKey: ECKDefaultKeys.enableSkillCompletedNotifications.rawValue)
        }
        set {
            setValue(newValue, forKey: ECKDefaultKeys.enableSkillCompletedNotifications.rawValue)
        }
    }
}
