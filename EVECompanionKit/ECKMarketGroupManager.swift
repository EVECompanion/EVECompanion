//
//  ECKMarketGroupManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 14.04.25.
//

import Foundation
public import Combine

public class ECKMarketGroupManager: ObservableObject {
    
    public var marketGroups: [ECKMarketGroup.ChildType] {
        if searchString.isEmpty {
            return allMarketGroups.filter({ $0.isEmpty == false })
        } else {
            return searchedItems
        }
    }
    
    @Published private var allMarketGroups: [ECKMarketGroup.ChildType] = []
    @Published private var searchedItems: [ECKMarketGroup.ChildType] = []
    public let groupIdFilter: Int?
    public let marketGroupIdFilter: Int?
    public let effectIdFilter: Int?
    
    @Published public var searchString: String = "" {
        didSet {
            searchItems(text: searchString)
        }
    }
    
    public init(groupIdFilter: Int?,
                marketGroupIdFilter: Int?,
                effectIdFilter: Int?) {
        self.groupIdFilter = groupIdFilter
        self.marketGroupIdFilter = marketGroupIdFilter
        self.effectIdFilter = effectIdFilter
        Task { @MainActor in
            if let groupIdFilter {
                self.searchedItems = ECKSDEManager.shared.itemSearch(text: "",
                                                                     groupIdFilter: groupIdFilter,
                                                                     marketGroupIdFilter: marketGroupIdFilter,
                                                                     effectIdFilter: effectIdFilter).map({ .item($0) })
                self.allMarketGroups = self.searchedItems.compactMap({ $0.item }).map({ .item($0) })
            } else {
                self.allMarketGroups = ECKSDEManager.shared.marketGroups(parentGroupId: marketGroupIdFilter,
                                                                         effectIdFilter: effectIdFilter).map({ .marketGroup($0) })
            }
        }
    }
    
    private func searchItems(text: String) {
        guard searchString.isEmpty == false else {
            self.searchedItems = []
            return
        }
        
        self.searchedItems = ECKSDEManager.shared.itemSearch(text: searchString,
                                                             groupIdFilter: groupIdFilter,
                                                             marketGroupIdFilter: marketGroupIdFilter,
                                                             effectIdFilter: effectIdFilter).map({ .item($0) })
    }
    
}
