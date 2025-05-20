//
//  ECKLogger.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import Foundation
@preconcurrency import SwiftyBeaver
import ZipArchive

final public class ECKLogger: Sendable {
    
    static let shared = ECKLogger()
    private let sb = SwiftyBeaver.self
    
    private let consoleDest = ConsoleDestination()
    private let fileDest = FileDestination()
    
    private let logfileExtension = "log"
    
    private let loggerQueue = DispatchQueue(label: "loggerQueue", qos: .background)
    
    private var dateFormatter: DateFormatter {
        let res = DateFormatter()
        res.dateFormat = "dd.MM.yyyy"
        
        return res
    }
    
    private var cacheDir: URL? {
        return try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    private var logDir: URL? {
        guard let cacheDirNonNil = cacheDir else {
            return nil
        }
        
        return URL(fileURLWithPath: cacheDirNonNil.path + "/log", isDirectory: true)
    }
    
    private var logZIPURL: URL? {
        guard let cacheDirNonNil = cacheDir else {
            return nil
        }
        
        return cacheDirNonNil.appendingPathComponent("logs-v\(ECKAppInfo.version)-\(ECKAppInfo.build).zip")
    }
    
    private var logFileURL: URL? {
        guard let logDirNonNil = logDir else {
            return nil
        }
        
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        
        return logDirNonNil.appendingPathComponent("\(dateString).\(logfileExtension)")
    }
    
    private var logFiles: [URL]? {
        guard let logDirNonNil = logDir else {
            return nil
        }
        
        guard let filesString = try? FileManager.default.contentsOfDirectory(atPath: logDirNonNil.path) else {
            return nil
        }
        
        return filesString.compactMap { (fileString) -> URL in
            return logDirNonNil.appendingPathComponent(fileString)
        }
    }
    
    internal init() {
        purgeLogFiles()
        setup()
    }
    
    private func purgeLogFiles() {
        guard let files = logFiles else {
            return
        }
        
        for file in files {
            let dateString = file.deletingPathExtension().lastPathComponent
            
            if let date = dateFormatter.date(from: dateString), date < Date() - TimeInterval.fromDays(days: 14) {
                do {
                    try FileManager.default.removeItem(at: file)
                } catch {
                    print("Error while purging logfile: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setup() {
        fileDest.minLevel = .info
        fileDest.logFileURL = logFileURL
        
        sb.addDestination(consoleDest)
        sb.addDestination(fileDest)
    }
    
    private func log(level: SwiftyBeaver.Level, _ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) {
        let thread = Thread.current.name ?? ""
        let message = String(describing: message())
        
        loggerQueue.async {
            _ = self.consoleDest.send(level,
                                      msg: "\(message)",
                                      thread: thread,
                                      file: file,
                                      function: function,
                                      line: line)
            
            _ = self.fileDest.send(level,
                                   msg: "\(message)",
                                   thread: thread,
                                   file: file,
                                   function: function,
                                   line: line)
        }
    }
    
    public func verbose(_ message: @autoclosure () -> Any, _ file: String = #fileID, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        log(level: .verbose, message(), file, function, line: line, context: context)
    }
    
    public func debug(_ message: @autoclosure () -> Any, _ file: String = #fileID, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        log(level: .debug, message(), file, function, line: line, context: context)
    }
    
    public func info(_ message: @autoclosure () -> Any, _ file: String = #fileID, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        log(level: .info, message(), file, function, line: line, context: context)
    }
    
    public func warning(_ message: @autoclosure () -> Any, _ file: String = #fileID, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        log(level: .warning, message(), file, function, line: line, context: context)
    }
    
    public func error(_ message: @autoclosure () -> Any, _ file: String = #fileID, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        log(level: .error, message(), file, function, line: line, context: context)
    }
    
    public func zipLogs() -> URL? {
        guard let zipFileURL = logZIPURL else {
            logger.error("Cannot build log zip url.")
            return nil
        }
        
        guard let logDirNonNil = logDir else {
            logger.error("Log Dir url is nil")
            return nil
        }
        
        guard SSZipArchive.createZipFile(atPath: zipFileURL.path,
                                         withContentsOfDirectory: logDirNonNil.path,
                                         keepParentDirectory: true,
                                         compressionLevel: -1,
                                         password: nil,
                                         aes: false,
                                         progressHandler: nil) else {
            logger.error("Zipping logs failed")
            return nil
        }
        
        return zipFileURL
    }
    
}

public let logger = ECKLogger.shared
