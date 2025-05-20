//
//  ECKAssetManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 23.06.24.
//

public import Combine

public class ECKAssetManager: ObservableObject {
    
    public let character: ECKCharacter
    let isPreview: Bool
    
    @Published public var searchText: String = ""
    public var assets: [ECKAssetLocation: [ECKAsset]]? {
        if searchText.isEmpty {
            return loadedAssets
        }
        
        return filteredAssets(searchText: searchText)
    }
    @Published var loadedAssets: [ECKAssetLocation: [ECKAsset]]?
    @Published public var loadingState: ECKLoadingState = .loading
    
    public var assetLocations: [ECKAssetLocation] {
        return Array((assets ?? .init()).keys).sorted { lhsLocation, rhsLocation in
            return lhsLocation.id < rhsLocation.id
        }
    }
    
    public init(character: ECKCharacter, isPreview: Bool = false) {
        self.character = character
        self.isPreview = isPreview
        Task {
            await loadAssets()
        }
    }
    
    @MainActor
    public func loadAssets() async {
        guard UserDefaults.standard.isDemoModeEnabled == false && isPreview == false else {
            self.loadedAssets = [.station(.jita): [.dummyAvatar]]
            self.loadingState = .ready
            return
        }
        
        if assets == nil {
            self.loadingState = .loading
        } else {
            self.loadingState = .reloading
        }
        
        do {
            let fetchedAssets = try await fetchAssets()
            let assetNames = await fetchAssetNames(itemIds: fetchedAssets.map({ $0.itemId }))
            var assetDictionary: [Int: ECKAsset] = [:]
            
            for asset in fetchedAssets {
                assetDictionary[asset.itemId] = asset
            }
            
            // First: Add all the item names
            for assetName in assetNames {
                assetDictionary[assetName.itemId]?.customName = assetName.name
            }
            
            // Second: Add all the container references
            for asset in fetchedAssets {
                switch asset.location {
                case .station:
                    continue
                    
                case .solarSystem:
                    continue
                    
                case .item(let itemId):
                    if let containingItem = assetDictionary[itemId] {
                        containingItem.contains.append(asset)
                        asset.containedIn = containingItem
                    } else if asset.locationFlag == .Hangar || asset.locationFlag == .HangarAll {
                        asset.location = .station(.init(stationId: itemId, token: character.token))
                    }
                    
                case .other(let id):
                    if let containingItem = assetDictionary[id] {
                        containingItem.contains.append(asset)
                        asset.containedIn = containingItem
                    } else if asset.locationFlag == .Hangar || asset.locationFlag == .HangarAll {
                        asset.location = .station(.init(stationId: id, token: character.token))
                    }
                    
                case .unknown:
                    continue
                    
                }
            }
            
            // Third: Sort all items contained within items
            for asset in fetchedAssets {
                asset.contains.sort(by: { lhsAsset, rhsAsset in
                    let lhsName: String
                    
                    if let lhsCustomName = lhsAsset.customName {
                        lhsName = lhsCustomName
                    } else {
                        lhsName = lhsAsset.item.name
                    }
                    
                    let rhsName: String
                    
                    if let rhsCustomName = rhsAsset.customName {
                        rhsName = rhsCustomName
                    } else {
                        rhsName = rhsAsset.item.name
                    }
                    
                    return lhsName < rhsName
                })
            }
            
            let baseAssets: [ECKAsset] = assetDictionary.values.filter { asset in
                return asset.containedIn == nil
            }
            
            var assetLocationDictionary: [ECKAssetLocation: [ECKAsset]] = [:]
            
            for asset in baseAssets {
                if assetLocationDictionary[asset.location] != nil {
                    assetLocationDictionary[asset.location]?.append(asset)
                } else {
                    assetLocationDictionary[asset.location] = [asset]
                }
            }
            
            for location in assetLocationDictionary.keys {
                let unsortedArray = assetLocationDictionary[location] ?? []
                let sortedArray = unsortedArray.sorted { lhsAsset, rhsAsset in
                    let lhsName: String
                    
                    if let lhsCustomName = lhsAsset.customName {
                        lhsName = lhsCustomName
                    } else {
                        lhsName = lhsAsset.item.name
                    }
                    
                    let rhsName: String
                    
                    if let rhsCustomName = rhsAsset.customName {
                        rhsName = rhsCustomName
                    } else {
                        rhsName = rhsAsset.item.name
                    }
                    
                    return lhsName < rhsName
                }
                assetLocationDictionary[location] = sortedArray
                
                self.loadedAssets = assetLocationDictionary
                self.loadingState = .ready
            }
        } catch {
            logger.error("Error while fetching assets \(error)")
            await MainActor.run {
                loadingState = .error
            }
        }
    }
    
    func fetchAssets() async throws -> [ECKAsset] {
        let firstAssetPageResource = ECKCharacterAssetsResource(token: character.token, page: 1)
        let firstPageResponse = try await ECKWebService().loadResource(resource: firstAssetPageResource)
        let firstPageAssets: [ECKAsset] = firstPageResponse.response
        
        let totalPages: Int = Int(firstPageResponse.headers["x-pages"] as? String ?? "") ?? 1
        
        let otherPageAssets: [ECKAsset] = try await withThrowingTaskGroup(of: [ECKAsset].self) { group -> [ECKAsset] in
            guard totalPages >= 2 else {
                return []
            }
            
            for page in 2...totalPages {
                group.addTask {
                    let resource = ECKCharacterAssetsResource(token: self.character.token, page: page)
                    return try await ECKWebService().loadResource(resource: resource).response
                }
            }
            
            var fetchedAssets = [ECKAsset]()

            for try await assets in group {
                fetchedAssets.append(contentsOf: assets)
            }
            
            return fetchedAssets
        }
        
        return firstPageAssets + otherPageAssets
    }
    
    func fetchAssetNames(itemIds: [Int]) async -> [ECKAssetName] {
        let chunkedIds: [[Int]] = itemIds.chunked(by: 1000)
        
        return await withTaskGroup(of: [ECKAssetName].self) { group -> [ECKAssetName] in
            for ids in chunkedIds {
                group.addTask {
                    let resource = ECKCharacterAssetNamesResource(token: self.character.token, itemIds: ids)
                    return (try? await ECKWebService().loadResource(resource: resource).response) ?? []
                }
            }
            
            var fetchedNames = [ECKAssetName]()
            
            for await names in group {
                fetchedNames.append(contentsOf: names)
            }
            
            return fetchedNames
        }
    }
    
    func filteredAssets(searchText: String) -> [ECKAssetLocation: [ECKAsset]]? {
        var result: [ECKAssetLocation: [ECKAsset]] = [:]
        
        guard let loadedAssets else {
            return nil
        }
        
        for location in Array(loadedAssets.keys) {
            var filteredAssets: [ECKAsset] = []
            
            for asset in loadedAssets[location] ?? [] where asset.includeInSearch(for: searchText) {
                let newAsset = asset.copy()
                newAsset.contains = newAsset.filteredChildren(for: searchText,
                                                              includeAllChildren: newAsset.isSearchResult(for: searchText))
                filteredAssets.append(newAsset)
            }
            
            if filteredAssets.isEmpty == false {
                result[location] = filteredAssets
            }
        }
        
        return result
    }
    
}
