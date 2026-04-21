//
//  ECKMarketOrderManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 01.04.26.
//

import Foundation
public import Combine

public enum ECKMarketOrderTypeFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case sell
    case buy
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .all:
            return "All"
        case .sell:
            return "Sell"
        case .buy:
            return "Buy"
        }
    }
}

public enum ECKMarketOrderSortOption: String, CaseIterable, Identifiable, Sendable {
    case issuedNewest
    case issuedOldest
    case priceHighToLow
    case priceLowToHigh
    case quantityHighToLow
    case quantityLowToHigh
    case nameAZ
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .issuedNewest:
            return "Issued: Newest"
        case .issuedOldest:
            return "Issued: Oldest"
        case .priceHighToLow:
            return "Price: High to Low"
        case .priceLowToHigh:
            return "Price: Low to High"
        case .quantityHighToLow:
            return "Quantity: High to Low"
        case .quantityLowToHigh:
            return "Quantity: Low to High"
        case .nameAZ:
            return "Name: A-Z"
        }
    }
}

public struct ECKMarketOrderSection: Identifiable, Sendable {
    public let title: String
    public let orders: [ECKMarketOrder]
    public let emptyText: String
    
    public var id: String {
        title
    }
}

public class ECKMarketOrderManager: ObservableObject, ECKPageLoadable, @unchecked Sendable {
    
    public enum Source: Equatable, Hashable, Sendable {
        case character(ECKCharacter)
        case corporation(ECKAuthenticatedCorporation)
        
        internal func resource(page: Int) -> ECKWebResource<[ECKMarketOrder]>? {
            switch self {
            case .character(let character):
                return ECKCharacterMarketOrdersResource(token: character.token, page: page)
            case .corporation(let corporation):
                guard let corpId = corporation.corpId else {
                    return nil
                }
                
                guard let roles = corporation.roles else {
                    return nil
                }
                
                return ECKCorporationMarketOrdersResource(
                    corporationId: corpId,
                    page: page,
                    token: corporation.authenticatingCharacter.token,
                    currentRoles: roles
                )
            }
        }
    }
    
    nonisolated public let source: Source
    let isPreview: Bool
    
    @Published public var marketOrders: [ECKMarketOrder]?
    @Published public var marketOrdersLoadingState: ECKLoadingState = .loading
    @Published public var searchText: String = ""
    @Published public var typeFilter: ECKMarketOrderTypeFilter = .all
    @Published public var sortOption: ECKMarketOrderSortOption = .issuedNewest
    
    private var pagination = ECKPagination()
    
    private var isSearching: Bool {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
    
    public var elements: [ECKMarketOrderSection] {
        var sections = [ECKMarketOrderSection]()
        
        if typeFilter != .buy {
            sections.append(.init(title: "Sell Orders",
                                  orders: sellOrders,
                                  emptyText: "No sell orders"))
        }
        
        if typeFilter != .sell {
            sections.append(.init(title: "Buy Orders",
                                  orders: buyOrders,
                                  emptyText: "No buy orders"))
        }
        
        if isSearching {
            return sections.filter { $0.orders.isEmpty == false }
        }
        
        return sections
    }
    
    public var hasNextPage: Bool {
        pagination.hasNextPage
    }
    
    public var filteredMarketOrders: [ECKMarketOrder] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchedOrders: [ECKMarketOrder]
        if trimmedSearchText.isEmpty {
            searchedOrders = marketOrders ?? []
        } else {
            searchedOrders = (marketOrders ?? []).filter { order in
                order.item.name.contains(trimmedSearchText)
                || (order.station.stationName?.contains(trimmedSearchText) ?? false)
                || order.region.name.contains(trimmedSearchText)
            }
        }
        
        return searchedOrders.sorted { lhs, rhs in
            switch sortOption {
            case .issuedNewest:
                return lhs.issued > rhs.issued
            case .issuedOldest:
                return lhs.issued < rhs.issued
            case .priceHighToLow:
                return lhs.price > rhs.price
            case .priceLowToHigh:
                return lhs.price < rhs.price
            case .quantityHighToLow:
                return lhs.volumeRemain > rhs.volumeRemain
            case .quantityLowToHigh:
                return lhs.volumeRemain < rhs.volumeRemain
            case .nameAZ:
                return lhs.item.name.localizedStandardCompare(rhs.item.name) == .orderedAscending
            }
        }
    }
    
    public var sellOrders: [ECKMarketOrder] {
        guard typeFilter != .buy else {
            return []
        }
        
        return filteredMarketOrders.filter { $0.isBuyOrder == false }
    }
    
    public var buyOrders: [ECKMarketOrder] {
        guard typeFilter != .sell else {
            return []
        }
        
        return filteredMarketOrders.filter { $0.isBuyOrder }
    }
    
    public convenience init(character: ECKCharacter, isPreview: Bool = false) {
        self.init(source: .character(character), isPreview: isPreview)
    }
    
    public convenience init(corporation: ECKAuthenticatedCorporation, isPreview: Bool = false) {
        self.init(source: .corporation(corporation), isPreview: isPreview)
    }
    
    public init(source: Source, isPreview: Bool = false) {
        self.source = source
        self.isPreview = isPreview
        Task { @MainActor in
            await loadMarketOrders()
        }
    }
    
    @MainActor
    public func loadMarketOrders() async {
        guard pagination.isLoading == false else {
            return
        }
        
        guard UserDefaults.standard.isDemoModeEnabled == false && isPreview == false else {
            marketOrders = [.dummy1, .dummy2]
            pagination = ECKPagination(totalPages: 1, lastLoadedPage: 1)
            marketOrdersLoadingState = .ready
            return
        }
        
        if marketOrders != nil {
            marketOrdersLoadingState = .reloading
        } else {
            marketOrdersLoadingState = .loading
        }
        
        guard let resource = source.resource(page: 1) else {
            return
        }
        
        do {
            pagination.reset()
            try await loadPage(with: resource, isFirstPage: true)
            self.marketOrdersLoadingState = .ready
        } catch {
            logger.error("Error loading market orders: \(String(describing: error))")
            self.marketOrdersLoadingState = .error(error)
        }
    }
    
    @MainActor
    public func reload() async {
        pagination.reset()
        await loadMarketOrders()
    }
    
    @MainActor
    public func loadNextPage() async throws(ECKWebError) {
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
    private func loadPage(with resource: ECKWebResource<[ECKMarketOrder]>, isFirstPage: Bool) async throws(ECKWebError) {
        pagination.setIsLoading(true)
        defer {
            pagination.setIsLoading(false)
        }
        
        let response = try await ECKWebService().loadResource(resource: resource)
        let loadedOrders = response.response
        
        if isFirstPage {
            marketOrders = loadedOrders
        } else {
            marketOrders = (marketOrders ?? []) + loadedOrders
        }
        
        pagination.next()
        pagination.setTotalPages(headers: response.headers)
        
        if loadedOrders.isEmpty,
           pagination.totalPages == nil {
            pagination.setTotalPages(pagination.lastLoadedPage)
        }
    }
    
}
