//
//  ECKIndustryJobManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.06.24.
//

public import Combine

public class ECKIndustryJobManager: ObservableObject, ECKPageLoadable, @unchecked Sendable {
    
    public enum Source: Equatable, Hashable, Sendable {
        case character(ECKCharacter)
        case corporation(ECKAuthenticatedCorporation)
        
        internal func resource(page: Int) -> ECKWebResource<[ECKIndustryJob]>? {
            switch self {
            case .character(let character):
                return ECKCharacterIndustryJobsResource(token: character.token, page: page)
            case .corporation(let corporation):
                guard let corpId = corporation.corpId else {
                    return nil
                }
                
                return ECKCorporationIndustryJobsResource(
                    corporationId: corpId,
                    page: page,
                    token: corporation.authenticatingCharacter.token
                )
            }
        }
        
        public var id: Int {
            switch self {
            case .character(let character):
                return character.id
            case .corporation(let corporation):
                return corporation.corpId ?? -1
            }
        }
    }
    
    public let source: Source
    let isPreview: Bool
    
    public var hasNextPage: Bool {
        pagination.hasNextPage
    }
    
    private var pagination = ECKPagination()
    @Published public var loadingState: ECKLoadingState = .loading
    @Published private var jobs: [ECKIndustryJob] = []
    
    public var elements: [ECKIndustryJob] { jobs }
    
    public convenience init(corporation: ECKAuthenticatedCorporation, isPreview: Bool = false) {
        self.init(source: .corporation(corporation), isPreview: isPreview)
    }
    
    public convenience init(character: ECKCharacter, isPreview: Bool = false) {
        self.init(source: .character(character), isPreview: isPreview)
    }
    
    public init(source: Source, isPreview: Bool = false) {
        self.source = source
        self.isPreview = isPreview
        Task { @MainActor in
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
            self.pagination = ECKPagination(totalPages: 1, lastLoadedPage: 1)
            self.loadingState = .ready
            return
        }
        
        if jobs.isEmpty {
            loadingState = .loading
        } else {
            loadingState = .reloading
        }
        
        guard let resource = source.resource(page: 1) else {
            pagination = ECKPagination(totalPages: 1, lastLoadedPage: 1)
            loadingState = .ready
            return
        }
        
        do {
            pagination.reset()
            try await loadPage(with: resource, isFirstPage: true)
            loadingState = .ready
        } catch {
            logger.error("Error while fetching industry jobs \(error)")
            loadingState = .error
        }
    }
    
    @MainActor
    public func reload() async {
        pagination.reset()
        await loadJobs()
    }
    
    @MainActor
    public func loadNextPage() async throws {
        guard pagination.isLoading == false else {
            return
        }
        
        guard pagination.hasNextPage else {
            return
        }
        
        let nextPage = pagination.lastLoadedPage + 1
        
        guard let resource = source.resource(page: nextPage) else {
            return
        }
        
        try await loadPage(with: resource, isFirstPage: false)
    }
    
    @MainActor
    private func loadPage(with resource: ECKWebResource<[ECKIndustryJob]>, isFirstPage: Bool) async throws {
        pagination.setIsLoading(true)
        defer {
            pagination.setIsLoading(false)
        }
        
        let response = try await ECKWebService().loadResource(resource: resource)
        let loadedJobs = response.response.reversed().filter({ $0.status != .cancelled && $0.status != .delivered })
        
        if isFirstPage {
            jobs = Array(loadedJobs)
        } else {
            jobs.append(contentsOf: loadedJobs)
        }
        
        pagination.next()
        pagination.setTotalPages(headers: response.headers)
            
        if loadedJobs.isEmpty,
           pagination.totalPages == nil {
            pagination.setTotalPages(pagination.lastLoadedPage)
        }
    }
    
}
