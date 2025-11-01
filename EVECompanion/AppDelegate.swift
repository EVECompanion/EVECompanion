//
//  AppDelegate.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 06.05.25.
//

import UIKit
import UserNotifications
import EVECompanionKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = ECKNotificationManager.shared
        FirebaseApp.configure()
        return true
    }
    
}
