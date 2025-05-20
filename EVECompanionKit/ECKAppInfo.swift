//
//  ECKAppInfo.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation

public struct ECKAppInfo {
    
    public static var appName: String {
        return (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String) ?? "EVECompanion"
    }
    
    public static var bundleId: String {
        return Bundle.main.bundleIdentifier ?? "unknown"
    }
    
    public static var version: String {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            logger.error("Cannot get version.")
            return "NA"
        }
        
        return version
    }
    
    public static var build: String {
        guard let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String else {
            logger.error("Cannot get build number.")
            return "NA"
        }
        
        return build
    }
    
}
