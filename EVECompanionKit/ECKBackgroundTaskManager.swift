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
        case widgetRefresh = "de.schlabertz.EVECompanion.widgetRefresh"
    }
    
    public static let shared: ECKBackgroundTaskManager = .init()
    
    private init() {
        
    }
    
    public func scheduleWidgetRefreshTask(scheduleRetry: Bool) {
        let request = BGAppRefreshTaskRequest(identifier: TaskType.widgetRefresh.rawValue)
        
        if scheduleRetry {
            request.earliestBeginDate = .now.addingTimeInterval(30 * 60)
        } else {
            request.earliestBeginDate = .now.addingTimeInterval(12 * 3600)
        }
        
        do {
            logger.info("Trying to schedule widget refresh task.")
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled widget refresh task.")
        } catch {
            logger.error("Error scheduling widget refresh task: \(error)")
        }
    }
    
}
