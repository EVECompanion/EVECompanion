//
//  ECKMiningLedgerManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.06.26.
//

public import Foundation
public import Combine

public class ECKMiningLedgerManager: ObservableObject, ECKPageLoadable, @unchecked Sendable {

    public let character: ECKCharacter
    let isPreview: Bool

    public var hasNextPage: Bool {
        pagination.hasNextPage
    }

    private var pagination = ECKPagination()
    @Published public var loadingState: ECKLoadingState = .loading
    @Published private var entries: [ECKMiningLedgerEntry] = []
    @Published private var daySummaries: [ECKMiningLedgerDaySummary] = []
    private var averagePrices: [Int: Double] = [:]

    public var elements: [ECKMiningLedgerDaySummary] {
        daySummaries
    }

    public init(character: ECKCharacter, isPreview: Bool = false) {
        self.character = character
        self.isPreview = isPreview

        Task { @MainActor in
            await loadMiningLedger()
        }
    }

    @MainActor
    public func loadMiningLedger() async {
        guard UserDefaults.standard.isDemoModeEnabled == false && isPreview == false else {
            self.entries = [
                .dummy1,
                .dummy2
            ]
            self.averagePrices = [
                ECKMiningLedgerEntry.dummy1.item.typeId: 8,
                ECKMiningLedgerEntry.dummy2.item.typeId: 12
            ]
            self.rebuildSummaries()
            self.pagination = ECKPagination(totalPages: 1, lastLoadedPage: 1)
            self.loadingState = .ready
            return
        }

        if entries.isEmpty {
            loadingState = .loading
        } else {
            loadingState = .reloading
        }

        let resource = ECKCharacterMiningLedgerResource(token: character.token, page: 1)

        do {
            pagination.reset()
            try await loadPage(with: resource, isFirstPage: true)
            loadingState = .ready
        } catch {
            logger.error("Error while fetching mining ledger \(error)")
            loadingState = .error(error)
        }
    }

    @MainActor
    public func reload() async {
        pagination.reset()
        await loadMiningLedger()
    }

    @MainActor
    public func loadNextPage() async throws(ECKWebError) {
        guard pagination.isLoading == false else {
            return
        }

        guard pagination.hasNextPage else {
            return
        }

        let nextPage = pagination.lastLoadedPage + 1
        let resource = ECKCharacterMiningLedgerResource(token: character.token, page: nextPage)

        try await loadPage(with: resource, isFirstPage: false)
    }

    @MainActor
    private func loadPage(with resource: ECKWebResource<[ECKMiningLedgerEntry]>, isFirstPage: Bool) async throws(ECKWebError) {
        pagination.setIsLoading(true)
        defer {
            pagination.setIsLoading(false)
        }

        let response = try await ECKWebService().loadResource(resource: resource)
        let loadedEntries = response.response

        if isFirstPage {
            entries = loadedEntries
        } else {
            entries.append(contentsOf: loadedEntries)
        }

        await loadPricesIfNeeded(for: loadedEntries)
        rebuildSummaries()

        pagination.next()
        pagination.setTotalPages(headers: response.headers)

        if loadedEntries.isEmpty,
           pagination.totalPages == nil {
            pagination.setTotalPages(pagination.lastLoadedPage)
        }
    }

    @MainActor
    private func loadPricesIfNeeded(for entries: [ECKMiningLedgerEntry]) async {
        let typeIds = Set(entries.map { $0.item.typeId })
            .filter { averagePrices[$0] == nil }

        await withTaskGroup(of: (Int, Double?).self) { group in
            for typeId in typeIds {
                group.addTask {
                    let averagePrice = await ECKMarketDataManager.shared.latestAveragePrice(forTypeId: typeId)
                    return (typeId, averagePrice)
                }
            }

            for await (typeId, averagePrice) in group {
                if let averagePrice {
                    averagePrices[typeId] = averagePrice
                }
            }
        }
    }

    @MainActor
    private func rebuildSummaries() {
        daySummaries = ECKMiningLedgerDaySummary.summaries(from: entries,
                                                           averagePrices: averagePrices)
    }

}
