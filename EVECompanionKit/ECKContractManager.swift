//
//  ECKContractManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 11.05.24.
//

public import Combine

public enum ECKContractStatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case outstanding
    case inProgress
    case failed
    case finished
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .all:
            return "All"
        case .outstanding:
            return "Outstanding"
        case .inProgress:
            return "In Progress"
        case .failed:
            return "Failed"
        case .finished:
            return "Finished"
        }
    }
    
    func matches(_ status: ECKContract.ECKContractStatus) -> Bool {
        switch self {
        case .all:
            return true
        case .outstanding:
            return status == .outstanding
        case .inProgress:
            return status == .inProgress
        case .failed:
            return status == .failed || status == .rejected
        case .finished:
            switch status {
            case .finishedIssuer,
                 .finishedContractor,
                 .finished,
                 .cancelled,
                 .deleted:
                return true
            case .outstanding,
                 .reversed,
                 .rejected,
                 .failed,
                 .inProgress:
                return false
            }
        }
    }
}

public enum ECKContractTypeFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case itemExchange
    case auction
    case courier
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .all:
            return "All Types"
        case .itemExchange:
            return "Item Exchange"
        case .auction:
            return "Auction"
        case .courier:
            return "Courier"
        }
    }
    
    var contractType: ECKContract.ECKContractType? {
        switch self {
        case .all:
            return nil
        case .itemExchange:
            return .itemExchange
        case .auction:
            return .auction
        case .courier:
            return .courier
        }
    }
}

public enum ECKContractSortOption: String, CaseIterable, Identifiable, Sendable {
    case issuedNewest
    case issuedOldest
    case expiresSoonest
    case titleAZ
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .issuedNewest:
            return "Issued: Newest"
        case .issuedOldest:
            return "Issued: Oldest"
        case .expiresSoonest:
            return "Expiry: Soonest"
        case .titleAZ:
            return "Title: A-Z"
        }
    }
}

public struct ECKContractSection: Identifiable, Sendable {
    public let title: String
    public let contracts: [ECKContract]
    
    public var id: String {
        title
    }
}

public class ECKContractManager: ObservableObject, ECKPageLoadable, @unchecked Sendable {
    
    public enum Source: Equatable, Hashable, Sendable {
        case character(ECKCharacter)
        case corporation(ECKAuthenticatedCorporation)
        
        internal func resource(page: Int) -> ECKWebResource<[ECKContract]>? {
            switch self {
            case .character(let character):
                return ECKCharacterContractResource(token: character.token, page: page)
            case .corporation(let corporation):
                guard let corpId = corporation.corpId else {
                    return nil
                }
                
                return ECKCorporationContractResource(corporationId: corpId,
                                                      page: page,
                                                      token: corporation.authenticatingCharacter.token)
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
    
    nonisolated public let source: Source
    let isPreview: Bool
    
    @Published public var loadingState: ECKLoadingState = .loading
    @Published public var contracts: [ECKContract] = []
    @Published public var searchText: String = ""
    @Published public var statusFilter: ECKContractStatusFilter = .all
    @Published public var typeFilter: ECKContractTypeFilter = .all
    @Published public var sortOption: ECKContractSortOption = .issuedNewest
    
    private var pagination = ECKPagination()
    
    public var elements: [ECKContractSection] {
        [
            ECKContractSection(title: "Outstanding", contracts: outstandingContracts),
            ECKContractSection(title: "In Progress", contracts: inProgressContracts),
            ECKContractSection(title: "Failed", contracts: failedContracts),
            ECKContractSection(title: "Finished", contracts: finishedContracts)
        ]
        .filter { $0.contracts.isEmpty == false }
    }
    
    public var hasNextPage: Bool {
        pagination.hasNextPage
    }
    
    public var outstandingContracts: [ECKContract] {
        return filteredContracts.filter { contract in
            return contract.status == .outstanding
        }
    }
    
    public var inProgressContracts: [ECKContract] {
        return filteredContracts.filter { contract in
            return contract.status == .inProgress
        }
    }
    
    public var failedContracts: [ECKContract] {
        return filteredContracts.filter { contract in
            return contract.status == .failed || contract.status == .rejected
        }
    }
    
    public var finishedContracts: [ECKContract] {
        return filteredContracts.filter { contract in
            switch contract.status {
            case .outstanding,
                 .reversed,
                 .rejected,
                 .failed,
                 .inProgress:
                return false
            case .finishedIssuer,
                 .finishedContractor,
                 .finished,
                 .cancelled,
                 .deleted:
                return true
            }
        }
    }
    
    public var filteredContracts: [ECKContract] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let searchedContracts = contracts.filter { contract in
            guard statusFilter.matches(contract.status) else {
                return false
            }
            
            if let contractType = typeFilter.contractType,
               contract.type != contractType {
                return false
            }
            
            guard trimmedSearchText.isEmpty == false else {
                return true
            }
            
            let title = contract.title ?? ""
            let startStationName = contract.startLocation.stationName ?? ""
            let startSystemName = contract.startLocation.solarSystem?.solarSystemName ?? ""
            let endStationName = contract.endLocation.stationName ?? ""
            let endSystemName = contract.endLocation.solarSystem?.solarSystemName ?? ""
            
            return title.contains(trimmedSearchText)
            || contract.type.title.contains(trimmedSearchText)
            || contract.availability.title.contains(trimmedSearchText)
            || startStationName.contains(trimmedSearchText)
            || startSystemName.contains(trimmedSearchText)
            || endStationName.contains(trimmedSearchText)
            || endSystemName.contains(trimmedSearchText)
        }
        
        return searchedContracts.sorted { lhs, rhs in
            switch sortOption {
            case .issuedNewest:
                return lhs.dateIssued > rhs.dateIssued
            case .issuedOldest:
                return lhs.dateIssued < rhs.dateIssued
            case .expiresSoonest:
                return lhs.dateExpired < rhs.dateExpired
            case .titleAZ:
                let lhsTitle = lhs.title ?? lhs.type.title
                let rhsTitle = rhs.title ?? rhs.type.title
                return lhsTitle.localizedStandardCompare(rhsTitle) == .orderedAscending
            }
        }
    }
    
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
            await loadContracts()
        }
    }
    
    @MainActor
    public func loadContracts() async {
        guard pagination.isLoading == false else {
            return
        }
        
        guard UserDefaults.standard.isDemoModeEnabled == false && isPreview == false else {
            self.contracts = [
                .dummyCourierOutstanding,
                .dummyCourierInProgress,
                .dummyCourierCompleted,
                .dummyCourierFailed,
                .dummyItemExchangeOutstanding,
                .dummyItemExchangeFinished
            ]
            self.pagination = ECKPagination(totalPages: 1, lastLoadedPage: 1)
            self.loadingState = .ready
            return
        }
        
        if contracts.isEmpty {
            loadingState = .loading
        } else {
            loadingState = .reloading
        }
        
        guard let resource = source.resource(page: 1) else {
            return
        }
        
        do {
            pagination.reset()
            try await loadPage(with: resource, isFirstPage: true)
            
            loadingState = .ready
        } catch {
            logger.error("Error while fetching contracts \(error)")
            loadingState = .error
        }
    }
    
    @MainActor
    public func reload() async {
        pagination.reset()
        await loadContracts()
    }
    
    @MainActor
    public func loadNextPage() async throws {
        guard pagination.isLoading == false else {
            return
        }
        
        guard hasNextPage else {
            return
        }
        
        let nextPage = pagination.lastLoadedPage + 1
        
        guard let resource = source.resource(page: nextPage) else {
            return
        }
        
        try await loadPage(with: resource, isFirstPage: false)
    }
    
    @MainActor
    private func loadPage(with resource: ECKWebResource<[ECKContract]>, isFirstPage: Bool) async throws {
        pagination.setIsLoading(true)
        defer {
            pagination.setIsLoading(false)
        }
        
        let response = try await ECKWebService().loadResource(resource: resource)
        let loadedContracts = response.response.reversed()
        
        if isFirstPage {
            contracts = Array(loadedContracts)
        } else {
            contracts.append(contentsOf: loadedContracts)
        }
        
        pagination.next()
        pagination.setTotalPages(headers: response.headers)
            
        if loadedContracts.isEmpty,
           pagination.totalPages == nil {
            pagination.setTotalPages(pagination.lastLoadedPage)
        }
    }
    
}
