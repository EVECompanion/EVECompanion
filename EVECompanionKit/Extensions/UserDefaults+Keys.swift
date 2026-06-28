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
    case showCorpTab = "showCorpTab"
    case showMapCharacterMarkers = "showMapCharacterMarkers"
    
    case industryJobActivityFilter = "industryJobActivityFilter"
    case industryJobSortOption = "industryJobSortOption"
    case contractStatusFilter = "contractStatusFilter"
    case contractTypeFilter = "contractTypeFilter"
    case contractSortOption = "contractSortOption"
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
    
    @objc dynamic var showCorpTab: Bool {
        get {
            if value(forKey: ECKDefaultKeys.showCorpTab.rawValue) == nil {
                return true
            }
            
            return bool(forKey: ECKDefaultKeys.showCorpTab.rawValue)
        }
        set {
            setValue(newValue, forKey: ECKDefaultKeys.showCorpTab.rawValue)
        }
    }
    
    @objc dynamic var showMapCharacterMarkers: Bool {
        get {
            if value(forKey: ECKDefaultKeys.showMapCharacterMarkers.rawValue) == nil {
                return true
            }
            
            return bool(forKey: ECKDefaultKeys.showMapCharacterMarkers.rawValue)
        }
        set {
            setValue(newValue, forKey: ECKDefaultKeys.showMapCharacterMarkers.rawValue)
        }
    }
    
    var industryJobActivityFilter: ECKIndustryJobManager.ActivityFilter {
        get {
            guard let storedValue = string(forKey: ECKDefaultKeys.industryJobActivityFilter.rawValue),
                  let filter = ECKIndustryJobManager.ActivityFilter(rawValue: storedValue) else {
                return .all
            }
            
            return filter
        }
        set {
            set(newValue.rawValue, forKey: ECKDefaultKeys.industryJobActivityFilter.rawValue)
        }
    }
    
    var industryJobSortOption: ECKIndustryJobManager.SortOption {
        get {
            guard let storedValue = string(forKey: ECKDefaultKeys.industryJobSortOption.rawValue),
                  let sortOption = ECKIndustryJobManager.SortOption(rawValue: storedValue) else {
                return .startedNewest
            }
            
            return sortOption
        }
        set {
            set(newValue.rawValue, forKey: ECKDefaultKeys.industryJobSortOption.rawValue)
        }
    }
    
    var contractStatusFilter: ECKContractStatusFilter {
        get {
            guard let storedValue = string(forKey: ECKDefaultKeys.contractStatusFilter.rawValue),
                  let filter = ECKContractStatusFilter(rawValue: storedValue) else {
                return .all
            }
            
            return filter
        }
        set {
            set(newValue.rawValue, forKey: ECKDefaultKeys.contractStatusFilter.rawValue)
        }
    }
    
    var contractTypeFilter: ECKContractTypeFilter {
        get {
            guard let storedValue = string(forKey: ECKDefaultKeys.contractTypeFilter.rawValue),
                  let filter = ECKContractTypeFilter(rawValue: storedValue) else {
                return .all
            }
            
            return filter
        }
        set {
            set(newValue.rawValue, forKey: ECKDefaultKeys.contractTypeFilter.rawValue)
        }
    }
    
    var contractSortOption: ECKContractSortOption {
        get {
            guard let storedValue = string(forKey: ECKDefaultKeys.contractSortOption.rawValue),
                  let sortOption = ECKContractSortOption(rawValue: storedValue) else {
                return .issuedNewest
            }
            
            return sortOption
        }
        set {
            set(newValue.rawValue, forKey: ECKDefaultKeys.contractSortOption.rawValue)
        }
    }
}
