//
//  ECKSDEUpdater.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 01.08.24.
//

import Foundation
public import Combine
import ZipArchive

@MainActor
public class ECKSDEUpdater: NSObject, ObservableObject {
    
    public enum State {
        case noUpdateAvailable
        case downloadRequired
        case updateAvailable
    }
    
    static let minimumSDEVersion: Int = 15
    @Published public var state: State = .noUpdateAvailable
    @Published public var fileSize: Double = 0
    @MainActor
    private var downloadProgressHandler: ((CGFloat) -> Void)?
    @MainActor
    private var downloadProgressObservation: NSKeyValueObservation?
    private var subscriptions = Set<AnyCancellable>()
    
    public override init() {
        super.init()
        
        NotificationCenter.default
            .publisher(for: .sdeDeleted)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                
                self.state = .downloadRequired
            }
            .store(in: &subscriptions)
    }
    
    @MainActor
    public func checkForUpdate() async {
        let resource = ECKSDEVersionResource()
        do {
            let versionResponse = try await ECKWebService().loadResource(resource: resource)
            fileSize = versionResponse.response.size
            
            let localVersion = UserDefaults.standard.localSDEVersion
            guard localVersion > 0 else {
                logger.info("Initial SDE download is necessary")
                state = .downloadRequired
                return
            }
            
            if localVersion < versionResponse.response.version {
                logger.info("An SDE Update is available.")
                state = localVersion < Self.minimumSDEVersion ? .downloadRequired : .updateAvailable
            } else {
                // Nothing to do here
                logger.info("No SDE Update necessary.")
                state = .noUpdateAvailable
            }
        } catch {
            logger.error("Error while loading SDE version: \(error)")
        }
    }
    
    @MainActor
    public func performSDEUpdate(downloadProgress: @escaping (CGFloat) -> Void) async throws {
        self.downloadProgressHandler = downloadProgress
        do {
            let result = try await downloadSDE()
            let data = try await extractSDE(result.url)
            try ECKSDEManager.shared.updateSDEFile(version: result.version,
                                                   data: data)
        } catch {
            throw error
        }
    }
    
    enum SDEDownloadError: Error {
        case fileNameNotSet
        case fileNameFormat
        case dataNotSet
        case urlNotSet
        case extractionError
    }
    
    @MainActor
    private func downloadSDE() async throws -> (version: Int, url: URL) {
        return try await withCheckedThrowingContinuation { continuation in
            let sessionConfig = URLSessionConfiguration.ephemeral
            let session = URLSession(configuration: sessionConfig)
            
            let request = URLRequest(url: URL(string: "https://\(Host.evecompanionAPI.value)/v2/sde")!)
            
            let task = session.downloadTask(with: request) { url, response, error in
                DispatchQueue.main.async {
                    self.downloadProgressObservation = nil
                    self.downloadProgressHandler = nil
                }
                
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let url else {
                    continuation.resume(throwing: SDEDownloadError.urlNotSet)
                    return
                }
                
                guard let fileName = response?.suggestedFilename else {
                    continuation.resume(throwing: SDEDownloadError.fileNameNotSet)
                    return
                }
                
                let fileNameComponents = fileName.components(separatedBy: ".")
                
                guard fileNameComponents.count == 2,
                      let version = Int(fileNameComponents[0]) else {
                    continuation.resume(throwing: SDEDownloadError.fileNameFormat)
                    return
                }
                
                let newURL = FileManager.default.temporaryDirectory.appending(path: fileName)
                // Remove the file in case it already exists.
                try? FileManager.default.removeItem(at: newURL)
                do {
                    try FileManager.default.moveItem(at: url,
                                                     to: newURL)
                } catch {
                    logger.error("Error while moving downloaded sde file: \(error)")
                    continuation.resume(throwing: SDEDownloadError.dataNotSet)
                    return
                }
                
                continuation.resume(returning: (version: version, url: newURL))
            }
            
            let progressHandler = self.downloadProgressHandler
            self.downloadProgressObservation = task.progress.observe(\.fractionCompleted, changeHandler: { progressObservation, _ in
                DispatchQueue.main.async {
                    progressHandler?(progressObservation.fractionCompleted)
                }
            })
            
            task.resume()
        }
    }
    
    private func extractSDE(_ url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let tempDirURL = FileManager.default.temporaryDirectory
            let fileURL = tempDirURL.appending(path: "EVE.sqlite")
            // Remove the file in case it already exists
            try? FileManager.default.removeItem(at: fileURL)
            SSZipArchive.unzipFile(atPath: url.path, toDestination: tempDirURL.path) { _, _, _, _ in
                return
            } completionHandler: { _, _, error in
                defer {
                    try? FileManager.default.removeItem(at: url)
                    try? FileManager.default.removeItem(at: fileURL)
                }
                
                if let error {
                    logger.error("Error extracting sde file: \(error)")
                    continuation.resume(throwing: SDEDownloadError.extractionError)
                    return
                }
                
                guard let data = try? Data(contentsOf: fileURL) else {
                    continuation.resume(throwing: SDEDownloadError.dataNotSet)
                    return
                }
                
                continuation.resume(returning: data)
            }
        }
    }
    
    public func confirmUpdate() {
        self.state = .noUpdateAvailable
    }
    
}
