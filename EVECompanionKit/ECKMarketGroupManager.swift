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
            return allMarketGroups
        } else {
            return searchedItems
        }
    }
    
    @Published private var allMarketGroups: [ECKMarketGroup.ChildType] = []
    @Published private var searchedItems: [ECKMarketGroup.ChildType] = []
    
    @Published public var searchString: String = "" {
        didSet {
            searchItems(text: searchString)
        }
    }
    
    public init() {
        Task { @MainActor in
            self.allMarketGroups = ECKSDEManager.shared.marketGroups(parentGroupId: nil).map({ .marketGroup($0) })
        }
    }
    
    private func searchItems(text: String) {
        guard searchString.isEmpty == false else {
            self.searchedItems = []
            return
        }
        
        self.searchedItems = ECKSDEManager.shared.itemSearch(text: searchString).map({ .item($0) })
    }
    
}
