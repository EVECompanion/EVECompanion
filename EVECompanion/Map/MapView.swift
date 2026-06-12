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

private struct MapAreaSearchTarget: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let center: CGPoint
    let bounds: CGRect
}

private enum MapSearchResult: Identifiable, Hashable {
    case solarSystem(ECKSolarSystem)
    case constellation(MapAreaSearchTarget)
    case region(MapAreaSearchTarget)
    
    var id: String {
        switch self {
        case .solarSystem(let system):
            return "system-\(system.id)"
        case .constellation(let constellation):
            return "constellation-\(constellation.id)"
        case .region(let region):
            return "region-\(region.id)"
        }
    }
    
    var title: String {
        switch self {
        case .solarSystem(let system):
            return system.solarSystemName
        case .constellation(let constellation):
            return constellation.name
        case .region(let region):
            return region.name
        }
    }
    
    var subtitle: String {
        switch self {
        case .solarSystem(let system):
            return system.region.name
        case .constellation(let constellation):
            return constellation.subtitle
        case .region(let region):
            return region.subtitle
        }
    }
    
    var iconName: String {
        switch self {
        case .solarSystem:
            return "sparkles"
        case .constellation:
            return "circle.hexagongrid"
        case .region:
            return "square.3.layers.3d"
        }
    }
}

private enum MapSearchLayout {
    static let horizontalPadding: CGFloat = 16
    static let topSafeAreaInsetAllowance: CGFloat = 16
    static let bottomPadding: CGFloat = 8
    static let stackSpacing: CGFloat = 8
    static let searchFieldHeight: CGFloat = 48
    static let searchControlSize: CGFloat = 32
    static let resultRowHeight: CGFloat = 56
    static let cornerRadius: CGFloat = 22
}

struct MapView: View {
    
    @State private var systems: [Int: ECKSolarSystem] = [:]
    @State private var gateConnections: [(solarSystemId: Int, destinationSolarSystemId: Int)] = []
    @State private var constellations: [String: CGPoint] = [:]
    @State private var regions: [String: CGPoint] = [:]
    @State private var constellationTargets: [MapAreaSearchTarget] = []
    @State private var regionTargets: [MapAreaSearchTarget] = []
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
        
        let constellationMatches = constellationTargets
            .filter { $0.name.localizedCaseInsensitiveContains(trimmedSearchText) }
            .sorted(using: KeyPathComparator(\.name))
            .prefix(12)
            .map(MapSearchResult.constellation)
        
        return Array(solarSystemMatches + constellationMatches + regionMatches).prefix(20).map(\.self)
    }
    
    private var searchResultsContentHeight: CGFloat {
        CGFloat(filteredSearchResults.count) * MapSearchLayout.resultRowHeight
    }
    
    private func averagePoint(for solarSystems: [ECKSolarSystem]) -> CGPoint? {
        let coordinates = solarSystems
            .compactMap(\.position2D)
            .map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
        
        guard coordinates.isEmpty == false else {
            return nil
        }
        
        let totalPoint = coordinates.reduce(CGPoint.zero) { partialResult, coordinate in
            CGPoint(
                x: partialResult.x + coordinate.x,
                y: partialResult.y + coordinate.y
            )
        }
        
        return CGPoint(
            x: totalPoint.x / CGFloat(coordinates.count),
            y: totalPoint.y / CGFloat(coordinates.count)
        )
    }
    
    private func bounds(for solarSystems: [ECKSolarSystem]) -> CGRect? {
        let coordinates = solarSystems
            .compactMap(\.position2D)
            .map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
        
        guard let firstCoordinate = coordinates.first else {
            return nil
        }
        
        return coordinates.dropFirst().reduce(
            CGRect(origin: firstCoordinate, size: .zero)
        ) { partialResult, coordinate in
            partialResult.union(CGRect(origin: coordinate, size: .zero))
        }
    }
    
    private func center(of bounds: CGRect) -> CGPoint {
        CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
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
                    let dbConstellations = Dictionary(
                        uniqueKeysWithValues: ECKSDEManager.shared
                            .getAllConstellations()
                            .map { ($0.constellationId, $0) }
                    )
                    systems = Dictionary(uniqueKeysWithValues: dbSystems.map { ($0.id, $0) })
                    
                    let groupedConstellations = Dictionary(grouping: dbSystems, by: \.constellationId)
                    let constellationCenters = groupedConstellations.compactMapValues { solarSystems in
                        averagePoint(for: solarSystems)
                    }
                    constellations = constellationCenters.reduce(into: [:]) { partialResult, constellationCenter in
                        let (constellationId, center) = constellationCenter
                        guard let constellation = dbConstellations[constellationId] else {
                            return
                        }
                        
                        partialResult[constellation.name] = center
                    }
                    constellationTargets = groupedConstellations.compactMap { constellationId, solarSystems in
                        guard let constellation = dbConstellations[constellationId],
                              let bounds = bounds(for: solarSystems) else {
                            return nil
                        }
                        
                        return MapAreaSearchTarget(
                            id: "\(constellation.constellationId)",
                            name: constellation.name,
                            subtitle: "\(constellation.region.name) Constellation",
                            center: center(of: bounds),
                            bounds: bounds
                        )
                    }
                    .sorted(using: KeyPathComparator(\.name))
                    
                    let groupedRegions = Dictionary(grouping: dbSystems, by: \.region.name)
                    regions = groupedRegions.compactMapValues { solarSystems in
                        averagePoint(for: solarSystems)
                    }
                    regionTargets = groupedRegions.compactMap { regionName, solarSystems in
                        guard let center = regions[regionName],
                              let bounds = bounds(for: solarSystems) else {
                            return nil
                        }
                        
                        return MapAreaSearchTarget(
                            id: regionName,
                            name: regionName,
                            subtitle: "Region",
                            center: center,
                            bounds: bounds
                        )
                    }
                    .sorted(using: KeyPathComparator(\.name))
                    
                    self.scene = MapScene(systems: systems, constellations: constellations, regions: regions, gateConnections: gateConnections)
                }
                
                searchOverlay(in: geometry)
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
            
        case .constellation(let constellation):
            let targetScale = scene.targetScaleToFit(
                rect: constellation.bounds,
                inset: MapScene.MapAreaHighlightInset.constellation
            )
            scene.focus(on: constellation.center, targetScale: targetScale) {
                scene.highlightConstellation(bounds: constellation.bounds)
            }
            
        case .region(let region):
            let targetScale = scene.targetScaleToFit(
                rect: region.bounds,
                inset: MapScene.MapAreaHighlightInset.region
            )
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
    
    private func searchOverlay(in geometry: GeometryProxy) -> some View {
        VStack(spacing: MapSearchLayout.stackSpacing) {
            searchResults(in: geometry)
            searchField
        }
        .padding(.horizontal, MapSearchLayout.horizontalPadding)
        .padding(.bottom, MapSearchLayout.bottomPadding)
    }
    
    @ViewBuilder
    private func searchResults(in geometry: GeometryProxy) -> some View {
        if filteredSearchResults.isEmpty == false {
            if searchResultsContentHeight <= searchResultsMaxHeight(in: geometry) {
                resultsList
                    .mapGlassPanel()
            } else {
                ScrollView {
                    resultsList
                }
                .frame(maxHeight: searchResultsMaxHeight(in: geometry), alignment: .bottom)
                .mapGlassPanel()
            }
        } else if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            Text("No matching solar systems, constellations, or regions.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .mapGlassPanel()
        }
    }
    
    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search solar systems, constellations, or regions", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
            
            if searchText.isEmpty == false {
                Button {
                    searchText = ""
                    isSearchFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .tint(.primary)
                .accessibilityLabel("Clear search")
            }
            
            keyboardDismissButton
                .opacity(isSearchFocused ? 1 : 0)
                .allowsHitTesting(isSearchFocused)
                .accessibilityHidden(isSearchFocused == false)
        }
        .padding(.horizontal, 14)
        .frame(height: MapSearchLayout.searchFieldHeight)
        .mapGlassPanel()
    }
    
    private var keyboardDismissButton: some View {
        Button {
            isSearchFocused = false
        } label: {
            Image(systemName: "keyboard.chevron.compact.down")
                .imageScale(.medium)
                .frame(width: MapSearchLayout.searchControlSize, height: MapSearchLayout.searchControlSize)
        }
        .mapGlassButtonStyle()
        .accessibilityLabel("Dismiss keyboard")
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
            - MapSearchLayout.topSafeAreaInsetAllowance
            - MapSearchLayout.searchFieldHeight
            - MapSearchLayout.stackSpacing
            - MapSearchLayout.bottomPadding
        
        guard availableHeight.isFinite else {
            return MapSearchLayout.resultRowHeight
        }
        
        return max(MapSearchLayout.resultRowHeight, availableHeight)
    }
    
}

private extension View {
    
    @ViewBuilder
    func mapGlassPanel() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular, in: RoundedRectangle(cornerRadius: MapSearchLayout.cornerRadius, style: .continuous))
        } else {
            background(.regularMaterial, in: RoundedRectangle(cornerRadius: MapSearchLayout.cornerRadius, style: .continuous))
        }
    }
    
    @ViewBuilder
    func mapGlassButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glass)
                .buttonBorderShape(.capsule)
        } else {
            buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
        }
    }
    
}

#Preview {
    MapView()
}
