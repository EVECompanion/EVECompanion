//
//  MapView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 19.05.26.
//

import SwiftUI
import EVECompanionKit
import simd
import SpriteKit

extension ECKSolarSystem {
    var cgPoint: CGPoint {
        guard let position2D else {
            return .zero
        }
        return CGPoint(x: Double(position2D.x), y: Double(position2D.y))
    }
}

private struct MapRegionSearchTarget: Identifiable, Hashable {
    let name: String
    let center: CGPoint
    let bounds: CGRect
    
    var id: String { name }
}

private enum MapSearchResult: Identifiable, Hashable {
    case solarSystem(ECKSolarSystem)
    case region(MapRegionSearchTarget)
    
    var id: String {
        switch self {
        case .solarSystem(let system):
            return "system-\(system.id)"
        case .region(let region):
            return "region-\(region.id)"
        }
    }
    
    var title: String {
        switch self {
        case .solarSystem(let system):
            return system.solarSystemName
        case .region(let region):
            return region.name
        }
    }
    
    var subtitle: String {
        switch self {
        case .solarSystem(let system):
            return system.region.name
        case .region:
            return "Region"
        }
    }
    
    var iconName: String {
        switch self {
        case .solarSystem:
            return "sparkles"
        case .region:
            return "square.3.layers.3d"
        }
    }
}

private enum MapSearchLayout {
    static let horizontalPadding: CGFloat = 16
    static let topPadding: CGFloat = 16
    static let stackSpacing: CGFloat = 8
    static let searchFieldHeight: CGFloat = 48
    static let resultRowHeight: CGFloat = 56
    static let emptyStateHeight: CGFloat = 44
    static let bottomSafeAreaInsetAllowance: CGFloat = 16
}

struct MapView: View {
    
    @State private var systems: [Int: ECKSolarSystem] = [:]
    @State private var gateConnections: [(solarSystemId: Int, destinationSolarSystemId: Int)] = []
    @State private var regions: [String: CGPoint] = [:]
    @State private var regionTargets: [MapRegionSearchTarget] = []
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    
    @State private var scene: MapScene?
    
    private var filteredSearchResults: [MapSearchResult] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedSearchText.isEmpty == false else {
            return []
        }
        
        let solarSystemMatches = systems.values
            .filter { $0.solarSystemName.localizedCaseInsensitiveContains(trimmedSearchText) }
            .sorted(using: KeyPathComparator(\.solarSystemName))
            .prefix(12)
            .map(MapSearchResult.solarSystem)
        
        let regionMatches = regionTargets
            .filter { $0.name.localizedCaseInsensitiveContains(trimmedSearchText) }
            .sorted(using: KeyPathComparator(\.name))
            .prefix(12)
            .map(MapSearchResult.region)
        
        return Array(solarSystemMatches + regionMatches).prefix(20).map(\.self)
    }
    
    private var searchResultsContentHeight: CGFloat {
        CGFloat(filteredSearchResults.count) * MapSearchLayout.resultRowHeight
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Group {
                    if let scene {
                        SpriteView(scene: scene)
                            .ignoresSafeArea()
                    } else {
                        ProgressView()
                    }
                }
                .task {
                    guard scene == nil else {
                        return
                    }
                    
                    gateConnections = ECKSDEManager.shared.getAllGateConnections()
                    let dbSystems = ECKSDEManager.shared.getAllSolarSystems()
                    systems = Dictionary(uniqueKeysWithValues: dbSystems.map { ($0.id, $0) })
                    
                    let groupedRegions = Dictionary(grouping: dbSystems, by: \.region.name)
                    regions = groupedRegions.mapValues { solarSystems in
                        let totalPoint = solarSystems.reduce(CGPoint.zero) { partialResult, solarSystem in
                            CGPoint(
                                x: partialResult.x + solarSystem.cgPoint.x,
                                y: partialResult.y + solarSystem.cgPoint.y
                            )
                        }
                        
                        return CGPoint(
                            x: totalPoint.x / CGFloat(solarSystems.count),
                            y: totalPoint.y / CGFloat(solarSystems.count)
                        )
                    }
                    regionTargets = groupedRegions.compactMap { regionName, solarSystems in
                        let coordinates = solarSystems
                            .compactMap(\.position2D)
                            .map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
                        
                        guard let firstCoordinate = coordinates.first,
                              let center = regions[regionName] else {
                            return nil
                        }
                        
                        let bounds = coordinates.dropFirst().reduce(
                            CGRect(origin: firstCoordinate, size: .zero)
                        ) { partialResult, coordinate in
                            partialResult.union(CGRect(origin: coordinate, size: .zero))
                        }
                        
                        return MapRegionSearchTarget(name: regionName, center: center, bounds: bounds)
                    }
                    .sorted(using: KeyPathComparator(\.name))
                    
                    self.scene = MapScene(systems: systems, regions: regions, gateConnections: gateConnections)
                }
                
                VStack(spacing: MapSearchLayout.stackSpacing) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Search solar systems or regions", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isSearchFocused)
                        
                        if searchText.isEmpty == false {
                            Button {
                                searchText = ""
                                isSearchFocused = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    if filteredSearchResults.isEmpty == false {
                        if searchResultsContentHeight <= searchResultsMaxHeight(in: geometry) {
                            resultsList
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        } else {
                            ScrollView {
                                resultsList
                            }
                            .frame(maxHeight: searchResultsMaxHeight(in: geometry), alignment: .top)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    } else if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                        Text("No matching solar systems or regions.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, MapSearchLayout.horizontalPadding)
                .padding(.top, MapSearchLayout.topPadding)
            }
        }
    }
    
    private func focus(on result: MapSearchResult) {
        guard let scene else {
            return
        }
        
        switch result {
        case .solarSystem(let system):
            scene.focus(on: system.cgPoint, targetScale: 0.4) {
                scene.highlightSystem(id: system.id)
            }
            
        case .region(let region):
            let targetScale = scene.targetScaleToFit(rect: region.bounds)
            scene.focus(on: region.center, targetScale: targetScale) {
                scene.highlightRegion(bounds: region.bounds)
            }
        }
        
        searchText = ""
        isSearchFocused = false
    }
    
    private var resultsList: some View {
        VStack(spacing: 0) {
            ForEach(filteredSearchResults) { result in
                resultButton(for: result)
            }
        }
    }
    
    private func resultButton(for result: MapSearchResult) -> some View {
        Button {
            focus(on: result)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: result.iconName)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .foregroundStyle(.primary)
                    Text(result.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .frame(minHeight: MapSearchLayout.resultRowHeight, alignment: .leading)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func searchResultsMaxHeight(in geometry: GeometryProxy) -> CGFloat {
        let availableHeight =
            geometry.size.height
            - MapSearchLayout.topPadding
            - MapSearchLayout.searchFieldHeight
            - MapSearchLayout.stackSpacing
            - MapSearchLayout.bottomSafeAreaInsetAllowance
        
        guard availableHeight.isFinite else {
            return MapSearchLayout.resultRowHeight
        }
        
        return max(MapSearchLayout.resultRowHeight, availableHeight)
    }
    
}

#Preview {
    MapView()
}
