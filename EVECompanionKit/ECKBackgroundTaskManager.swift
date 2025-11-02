//
//  ECKBackgroundTaskManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 31.10.25.
//

import Foundation
public import Combine
import BackgroundTasks

public class ECKBackgroundTaskManager: ObservableObject {
    
    public enum TaskType: String {
        case refreshTask = "de.schlabertz.EVECompanion.refreshTask"
    }
    
    public static let shared: ECKBackgroundTaskManager = .init()
    
    private init() {
        
    }
    
    public func scheduleAppRefreshTask() {
        let request = BGAppRefreshTaskRequest(identifier: TaskType.refreshTask.rawValue)
        #if DEBUG
        request.earliestBeginDate = .now.addingTimeInterval(3600)
        #else
        request.earliestBeginDate = .now.addingTimeInterval(12 * 3600)
        #endif
        
        do {
            logger.info("Trying to schedule widget refresh task. Earliest begin date: \(String(describing: request.earliestBeginDate))")
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled widget refresh task.")
        } catch {
            logger.error("Error scheduling widget refresh task: \(error)")
        }
    }
    
}
