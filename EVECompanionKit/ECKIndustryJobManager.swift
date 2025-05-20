//
//  ECKIndustryJobManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.06.24.
//

public import Combine

public class ECKIndustryJobManager: ObservableObject {
    
    public let character: ECKCharacter
    let isPreview: Bool
    
    @Published public var loadingState: ECKLoadingState = .loading
    @Published public var jobs: [ECKIndustryJob] = []
    
    public init(character: ECKCharacter, isPreview: Bool = false) {
        self.character = character
        self.isPreview = isPreview
        Task {
            await loadJobs()
        }
    }
    
    @MainActor
    public func loadJobs() async {
        guard UserDefaults.standard.isDemoModeEnabled == false && isPreview == false else {
            self.jobs = [
                .dummyActive,
                .dummyPaused
            ]
            self.loadingState = .ready
            return
        }
        
        if jobs.isEmpty {
            loadingState = .loading
        } else {
            loadingState = .reloading
        }
        
        let resource = ECKCharacterIndustryJobsResource(token: character.token)
        do {
            let jobs = try await ECKWebService().loadResource(resource: resource).response
            self.jobs = jobs.filter({ $0.status != .cancelled && $0.status != .delivered })
            loadingState = .ready
        } catch {
            logger.error("Error while fetching industry jobs \(error)")
            loadingState = .error
        }
    }
    
}
