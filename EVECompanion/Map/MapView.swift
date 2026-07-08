//
//  MapView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 19.05.26.
//

import SwiftUI
import EVECompanionKit
import SpriteKit
import Combine
import UIKit

private extension ECKSolarSystem {
    var mapPoint: CGPoint? {
        position2D.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
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

struct MapSystemSelectionConfiguration {
    let selectableSystemIds: Set<Int>
    let highlightedSystemIds: Set<Int>
    let replacementSystemId: Int?
    let jumpRouteSystemIds: [Int]
    let initialFocusSystem: ECKSolarSystem?
    let systemSelected: (ECKSolarSystem) -> Void

    init(selectableSystemIds: Set<Int>,
         highlightedSystemIds: Set<Int>,
         replacementSystemId: Int? = nil,
         jumpRouteSystemIds: [Int] = [],
         initialFocusSystem: ECKSolarSystem?,
         systemSelected: @escaping (ECKSolarSystem) -> Void) {
        self.selectableSystemIds = selectableSystemIds
        self.highlightedSystemIds = highlightedSystemIds
        self.replacementSystemId = replacementSystemId
        self.jumpRouteSystemIds = jumpRouteSystemIds
        self.initialFocusSystem = initialFocusSystem
        self.systemSelected = systemSelected
    }
}

struct MapSearchResetControlState {
    let searchText: String
    let hasSearchSelection: Bool
    let selectedTitle: String?

    var isVisible: Bool {
        searchText.isEmpty == false || hasSearchSelection
    }
    
    var selectedDisplayText: String? {
        guard searchText.isEmpty, hasSearchSelection else {
            return nil
        }
        
        return selectedTitle
    }
    
    func searchTextAfterFocusChange(isFocused: Bool) -> String {
        guard hasSearchSelection, let selectedTitle else {
            return searchText
        }
        
        if isFocused {
            return searchText.isEmpty ? selectedTitle : searchText
        }
        
        return ""
    }
}

private enum MapCharacterLocations {
    static let refreshIntervalNanoseconds: UInt64 = 30 * 1_000_000_000
}

private enum MapSelectionFocus {
    static let singleSystemScale: CGFloat = 0.4
    static let highlightedSystemsPadding: CGFloat = 1.25
    static let highlightedSystemsInset: CGFloat = 80
}

private struct MapLoadedData {
    let systems: [Int: ECKSolarSystem]
    let gateConnections: [(solarSystemId: Int, destinationSolarSystemId: Int)]
    let constellationsById: [Int: ECKConstellation]
    let constellations: [String: CGPoint]
    let regions: [String: CGPoint]
    let constellationTargets: [MapAreaSearchTarget]
    let regionTargets: [MapAreaSearchTarget]
}

private enum MapDataLoader {

    static func load() async -> MapLoadedData {
        await withCheckedContinuation { continuation in
            DispatchQueue(label: "MapDataLoaderQueue", qos: .userInitiated).async {
                continuation.resume(returning: loadSynchronously())
            }
        }
    }

    private static func loadSynchronously() -> MapLoadedData {
        let gateConnections = ECKSDEManager.shared.getAllGateConnections()
        let dbSystems = ECKSDEManager.shared.getAllSolarSystems()
        let dbConstellations = Dictionary(
            uniqueKeysWithValues: ECKSDEManager.shared
                .getAllConstellations()
                .map { ($0.constellationId, $0) }
        )

        let groupedConstellations = Dictionary(grouping: dbSystems, by: \.constellationId)
        let constellationCenters = groupedConstellations.compactMapValues { solarSystems in
            averagePoint(for: solarSystems)
        }
        let constellations: [String: CGPoint] = constellationCenters.reduce(into: [:]) { partialResult, constellationCenter in
            let (constellationId, center) = constellationCenter
            guard let constellation = dbConstellations[constellationId] else {
                return
            }

            partialResult[constellation.name] = center
        }
        let constellationTargets: [MapAreaSearchTarget] = groupedConstellations.compactMap { constellationId, solarSystems in
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
        .sorted { lhs, rhs in
            lhs.name < rhs.name
        }

        let groupedRegions = Dictionary(grouping: dbSystems, by: \.region.name)
        let regions: [String: CGPoint] = groupedRegions.compactMapValues { solarSystems in
            averagePoint(for: solarSystems)
        }
        let regionTargets: [MapAreaSearchTarget] = groupedRegions.compactMap { regionName, solarSystems in
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
        .sorted { lhs, rhs in
            lhs.name < rhs.name
        }

        return MapLoadedData(
            systems: Dictionary(uniqueKeysWithValues: dbSystems.map { ($0.id, $0) }),
            gateConnections: gateConnections,
            constellationsById: dbConstellations,
            constellations: constellations,
            regions: regions,
            constellationTargets: constellationTargets,
            regionTargets: regionTargets
        )
    }

    static func averagePoint(for solarSystems: [ECKSolarSystem]) -> CGPoint? {
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

    static func bounds(for solarSystems: [ECKSolarSystem]) -> CGRect? {
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

    static func center(of bounds: CGRect) -> CGPoint {
        CGPoint(x: bounds.midX, y: bounds.midY)
    }

}

struct MapView: View {
    
    @Environment(\.characterStorage) private var characterStorage
    @Environment(\.colorScheme) private var colorScheme

    @State private var systems: [Int: ECKSolarSystem] = [:]
    @State private var gateConnections: [(solarSystemId: Int, destinationSolarSystemId: Int)] = []
    @State private var constellationsById: [Int: ECKConstellation] = [:]
    @State private var constellations: [String: CGPoint] = [:]
    @State private var regions: [String: CGPoint] = [:]
    @State private var constellationTargets: [MapAreaSearchTarget] = []
    @State private var regionTargets: [MapAreaSearchTarget] = []
    @State private var searchText: String = ""
    @State private var hasSearchSelection: Bool = false
    @State private var selectedSearchResultTitle: String?
    @AppStorage(ECKDefaultKeys.showMapCharacterMarkers.rawValue) private var showCharacterMarkers: Bool = true
    @State private var characterMarkers: [MapScene.CharacterMarker] = []
    @State private var selectedSystemDetails: ECKMapSystemDetails?
    @State private var selectedSystemDetailsDetent: PresentationDetent = .medium
    @FocusState private var isSearchFocused: Bool
    
    @State private var scene: MapScene?
    @State private var viewportSize: CGSize = .zero
    @State private var didApplyInitialFocus: Bool = false

    // MARK: - New state variables for proposed alternative system selection
    @State private var proposedReplacementSystemId: Int? // Tracks proposed alternative system
    @State private var isProposingSelection: Bool = false // True when previewing alternative
    
    // MARK: - New state variable to track previewed jump route with proposed alternative
    @State private var proposedJumpRouteSystemIds: [Int]?

    private let selectionConfiguration: MapSystemSelectionConfiguration?
    private let showsCharacterMarkers: Bool
    private let showsSearchBar: Bool

    init(selectionConfiguration: MapSystemSelectionConfiguration? = nil,
         showsCharacterMarkers: Bool = true,
         showsSearchBar: Bool = true) {
        self.selectionConfiguration = selectionConfiguration
        self.showsCharacterMarkers = showsCharacterMarkers
        self.showsSearchBar = showsSearchBar
    }
    
    private var filteredSearchResults: [MapSearchResult] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedSearchText.isEmpty == false else {
            return []
        }
        
        let solarSystemMatches = systems.values
            .filter { $0.solarSystemName.localizedCaseInsensitiveContains(trimmedSearchText) }
            .filter { isSearchableSolarSystem($0) }
            .sorted(using: KeyPathComparator(\.solarSystemName))
            .prefix(12)
            .map(MapSearchResult.solarSystem)
        
        let regionMatches = regionTargets
            .filter { $0.name.localizedCaseInsensitiveContains(trimmedSearchText) }
            .sorted { lhs, rhs in
                lhs.name < rhs.name
            }
            .prefix(12)
            .map(MapSearchResult.region)
        
        let constellationMatches = constellationTargets
            .filter { $0.name.localizedCaseInsensitiveContains(trimmedSearchText) }
            .sorted { lhs, rhs in
                lhs.name < rhs.name
            }
            .prefix(12)
            .map(MapSearchResult.constellation)
        
        return Array((solarSystemMatches + constellationMatches + regionMatches).prefix(20))
    }

    private var isSystemDetailsSheetPresented: Binding<Bool> {
        Binding(get: {
            selectedSystemDetails != nil
        }, set: { isPresented in
            if isPresented == false {
                selectedSystemDetails = nil
                selectedSystemDetailsDetent = .medium
            }
        })
    }

    private var searchResetControlState: MapSearchResetControlState {
        MapSearchResetControlState(
            searchText: searchText,
            hasSearchSelection: hasSearchSelection,
            selectedTitle: selectedSearchResultTitle
        )
    }

    private func isSearchableSolarSystem(_ system: ECKSolarSystem) -> Bool {
        guard let selectionConfiguration else {
            return true
        }

        return selectionConfiguration.selectableSystemIds.contains(system.id)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let scene {
                    SpriteView(scene: scene)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .modifier(
                            MapSafeAreaIgnoringModifier(
                                isEnabled: showsSearchBar || isProposingSelection
                            )
                        )
                        .onAppear {
                            attemptInitialFocusIfNeeded()
                        }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .task {
                guard scene == nil else {
                    return
                }

                let loadedData = await MapDataLoader.load()
                guard Task.isCancelled == false else {
                    return
                }

                gateConnections = loadedData.gateConnections
                systems = loadedData.systems
                constellationsById = loadedData.constellationsById
                constellations = loadedData.constellations
                regions = loadedData.regions
                constellationTargets = loadedData.constellationTargets
                regionTargets = loadedData.regionTargets

                let mapScene = MapScene(
                    systems: loadedData.systems,
                    constellations: loadedData.constellations,
                    regions: loadedData.regions,
                    gateConnections: loadedData.gateConnections
                )
                mapScene.systemSelected = { systemId in
                    selectSystem(id: systemId)
                }
                configureSelectionOverlays(in: mapScene)
                self.scene = mapScene
                attemptInitialFocusIfNeeded()
            }
            .task(id: scene != nil) {
                guard scene != nil,
                      showsCharacterMarkers else {
                    return
                }

                await runCharacterLocationUpdates()
            }
            .onReceive(characterStorage.$characters) { _ in
                guard showsCharacterMarkers else {
                    return
                }

                Task {
                    await refreshCharacterMarkers()
                }
            }
            .onChange(of: showCharacterMarkers) { isVisible in
                guard showsCharacterMarkers else {
                    return
                }

                scene?.setCharactersVisible(isVisible)
            }
            .onChange(of: colorScheme) { newColorScheme in
                scene?.refreshAppearance(userInterfaceStyle: newColorScheme.userInterfaceStyle)
            }

            if showsSearchBar {
                searchOverlay(size: viewportSize)
            }
            
            // MARK: - Confirm selection button
            if isProposingSelection {
                VStack {
                    Spacer()
                    Button("Confirm") {
                        guard let selectionConfig = selectionConfiguration,
                              let id = proposedReplacementSystemId,
                              let system = systems[id] else { return }
                        // Confirm the proposed alternative system selection
                        selectionConfig.systemSelected(system)
                        isProposingSelection = false
                        proposedReplacementSystemId = nil
                        // Reset proposed jump route after confirmation
                        proposedJumpRouteSystemIds = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: isProposingSelection)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        updateViewportSize(geometry.size)
                    }
                    .onChange(of: geometry.size) { newSize in
                        updateViewportSize(newSize)
                    }
            }
        }
        .onAppear {
            // When reopening the map, ensure selection overlays and focus are reapplied
            attemptInitialFocusIfNeeded()
        }
        .toolbar {
            if showsCharacterMarkers {
                ToolbarItem(placement: .topBarTrailing) {
                    characterVisibilityButton
                }
            }
        }
        .sheet(isPresented: isSystemDetailsSheetPresented) {
            if let selectedSystemDetails {
                NavigationStack {
                    MapSystemDetailsView(
                        details: selectedSystemDetails,
                        logoSource: sovereigntyLogoSource(for: selectedSystemDetails)
                    )
                }
                .presentationDetents([.medium, .large], selection: $selectedSystemDetailsDetent)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            }
        }
    }
    
    @MainActor
    private func runCharacterLocationUpdates() async {
        scene?.setCharactersVisible(showCharacterMarkers)
        scene?.updateCharacters(characterMarkers)
        await refreshCharacterMarkers()

        while Task.isCancelled == false {
            do {
                try await Task.sleep(nanoseconds: MapCharacterLocations.refreshIntervalNanoseconds)
            } catch {
                return
            }

            await refreshCharacterMarkers()
        }
    }

    @MainActor
    private func refreshCharacterMarkers() async {
        guard scene != nil else {
            return
        }

        let characters = characterStorage.characters.filter(\.hasValidToken)

        await withTaskGroup(of: Void.self) { taskGroup in
            for character in characters {
                taskGroup.addTask {
                    await character.reloadMapLocationData()
                }
            }
        }

        let markers = characters.compactMap { character -> MapScene.CharacterMarker? in
            guard let solarSystemId = character.location?.solarSystem.id else {
                return nil
            }

            return MapScene.CharacterMarker(
                characterId: character.id,
                name: character.name,
                solarSystemId: solarSystemId,
                isOnline: character.isOnline
            )
        }

        characterMarkers = markers
        scene?.updateCharacters(markers)
        scene?.setCharactersVisible(showCharacterMarkers)

        if let selectedSystemId = selectedSystemDetails?.id {
            selectedSystemDetails = details(for: selectedSystemId)
        }
    }

    // MARK: - Modified selectSystem to handle proposed alternative selection preview
    private func selectSystem(id systemId: Int) {
        if let selectionConfiguration {
            // Only highlighted systems are valid alternatives for preview
            // If systemId is not in highlightedSystemIds, fallback to default selection behavior
            if proposedReplacementSystemId != systemId && systemId != selectionConfiguration.replacementSystemId {
                guard selectionConfiguration.highlightedSystemIds.contains(systemId) else {
                    // Not a highlighted system: do not propose as alternative
                    // Fall through to default selection behavior below
                    return
                }
                // Set proposed replacement and enter proposing mode
                proposedReplacementSystemId = systemId
                isProposingSelection = true
                
                // Calculate jump route system IDs for proposed alternative by replacing the original replacement ID with proposed ID in the jump route
                proposedJumpRouteSystemIds = calculateJumpRoute(for: systemId) ?? selectionConfiguration.jumpRouteSystemIds
                
                // Redraw overlays with proposedReplacementSystemId as replacement
                if let scene = scene {
                    scene.drawJumpRoute(systemIds: proposedJumpRouteSystemIds ?? [])
                    scene.highlightSystems(ids: selectionConfiguration.highlightedSystemIds)
                    scene.highlightReplacementSystem(id: proposedReplacementSystemId)
                }
                return
            }
            
            // If selecting the same system as current replacement or confirming alternative, fall back to original behavior
            if !isProposingSelection {
                guard selectionConfiguration.selectableSystemIds.contains(systemId),
                      let system = systems[systemId] else {
                    return
                }

                selectionConfiguration.systemSelected(system)
                return
            }
        }

        // If no selection configuration or not proposing alternative, show system details sheet
        selectedSystemDetailsDetent = .medium
        selectedSystemDetails = details(for: systemId)
    }
    
    /// Calculates a jump route array replacing the original replacement system ID with the proposed system ID.
    /// Returns the updated jump route system IDs, or the original if no replacement ID is found.
    private func calculateJumpRoute(for proposedSystemId: Int) -> [Int]? {
        guard let selectionConfiguration,
              let replacementId = selectionConfiguration.replacementSystemId else {
            return nil
        }

        if let index = selectionConfiguration.jumpRouteSystemIds.firstIndex(of: replacementId) {
            var updatedRoute = selectionConfiguration.jumpRouteSystemIds
            updatedRoute[index] = proposedSystemId
            return updatedRoute
        }

        return selectionConfiguration.jumpRouteSystemIds
    }

    private func updateViewportSize(_ newSize: CGSize) {
        viewportSize = newSize
        attemptInitialFocusIfNeeded()

        guard let scene,
              selectionConfiguration != nil else {
            return
        }

        let isFiniteSize = newSize.width.isFinite && newSize.height.isFinite && newSize.width > 0 && newSize.height > 0
        let validViewport: CGSize? = isFiniteSize ? newSize : nil

        // If we've already applied the initial focus, allow dynamic refocus on further size changes
        if didApplyInitialFocus, let validViewport {
            focusOnSelection(in: scene, viewportSize: validViewport)
        }
    }

    // MARK: - Modified configureSelectionOverlays to use proposedReplacementSystemId and proposedJumpRouteSystemIds if present
    private func configureSelectionOverlays(in scene: MapScene) {
        guard let selectionConfiguration else {
            return
        }
        
        // Use proposedReplacementSystemId if it exists, otherwise use the original replacementSystemId
        let replacementIdToUse = proposedReplacementSystemId ?? selectionConfiguration.replacementSystemId
        // Use proposedJumpRouteSystemIds if set, else fallback to original jumpRouteSystemIds
        let jumpRouteToUse = proposedJumpRouteSystemIds ?? selectionConfiguration.jumpRouteSystemIds
        
        scene.drawJumpRoute(systemIds: jumpRouteToUse)
        scene.highlightSystems(ids: selectionConfiguration.highlightedSystemIds)
        scene.highlightReplacementSystem(id: replacementIdToUse)
    }

    @discardableResult
    private func focusOnSelection(in scene: MapScene, viewportSize: CGSize? = nil) -> Bool {
        if let selectionConfiguration {
            let focusSystemIds = ECKCapitalJumpMapOverlay.focusSystemIds(
                highlightedSystemIds: selectionConfiguration.highlightedSystemIds,
                replacementSystemId: selectionConfiguration.replacementSystemId
            )

            // Prefer highlighted systems; if none, fall back to the route systems
            var systemsToFocus = focusSystemIds.compactMap { systems[$0] }
            if systemsToFocus.isEmpty {
                systemsToFocus = selectionConfiguration.jumpRouteSystemIds.compactMap { systems[$0] }
            }

            if let bounds = MapDataLoader.bounds(for: systemsToFocus) {
                let targetScale: CGFloat
                if systemsToFocus.count == 1 || bounds.size == .zero {
                    targetScale = MapSelectionFocus.singleSystemScale
                } else {
                    targetScale = scene.targetScaleToFit(
                        rect: bounds,
                        padding: MapSelectionFocus.highlightedSystemsPadding,
                        inset: MapSelectionFocus.highlightedSystemsInset,
                        viewportSize: viewportSize
                    )
                }

                scene.focus(on: MapDataLoader.center(of: bounds), targetScale: targetScale, animated: false)
                return true
            }
        }

        if let initialFocusSystem = selectionConfiguration?.initialFocusSystem,
           let mapPoint = initialFocusSystem.mapPoint {
            scene.focus(on: mapPoint,
                        targetScale: MapSelectionFocus.singleSystemScale,
                        animated: false)
            return true
        }

        return false
    }

    private func details(for systemId: Int) -> ECKMapSystemDetails? {
        guard let system = systems[systemId] else {
            return nil
        }

        let charactersInSystem = characterStorage.characters
            .filter { $0.location?.solarSystem.id == systemId }

        return ECKMapSystemDetails(
            system: system,
            constellationName: constellationsById[system.constellationId]?.name ?? "Unknown Constellation",
            stations: ECKSDEManager.shared.getStations(solarSystemId: systemId),
            characters: charactersInSystem
        )
    }

    private func sovereigntyLogoSource(for details: ECKMapSystemDetails) -> ECKSolarSystemImageSource? {
        systems[details.id]?.sovereigntyLogoSource
    }

    private func focus(on result: MapSearchResult) {
        guard let scene else {
            return
        }
        
        switch result {
        case .solarSystem(let system):
            guard let mapPoint = system.mapPoint else {
                return
            }
            scene.focus(on: mapPoint, targetScale: 0.4) {
                scene.highlightSystem(id: system.id)
                hasSearchSelection = scene.hasSelectionHighlight
                selectedSearchResultTitle = result.title
            }
            
        case .constellation(let constellation):
            let targetScale = scene.targetScaleToFit(
                rect: constellation.bounds,
                inset: MapScene.MapAreaHighlightInset.constellation
            )
            scene.focus(on: constellation.center, targetScale: targetScale) {
                scene.highlightConstellation(bounds: constellation.bounds)
                hasSearchSelection = scene.hasSelectionHighlight
                selectedSearchResultTitle = result.title
            }
            
        case .region(let region):
            let targetScale = scene.targetScaleToFit(
                rect: region.bounds,
                inset: MapScene.MapAreaHighlightInset.region
            )
            scene.focus(on: region.center, targetScale: targetScale) {
                scene.highlightRegion(bounds: region.bounds)
                hasSearchSelection = scene.hasSelectionHighlight
                selectedSearchResultTitle = result.title
            }
        }
        
        searchText = ""
        isSearchFocused = false
    }
    
    private func resultsList(_ results: [MapSearchResult]) -> some View {
        VStack(spacing: 0) {
            ForEach(results) { result in
                resultButton(for: result)
            }
        }
    }
    
    private func searchOverlay(size: CGSize) -> some View {
        VStack(spacing: MapSearchLayout.stackSpacing) {
            searchResults(filteredSearchResults, availableSize: size)
            searchField
        }
        .padding(.horizontal, MapSearchLayout.horizontalPadding)
        .padding(.bottom, MapSearchLayout.bottomPadding)
        .onChange(of: isSearchFocused) { isFocused in
            updateSearchFocus(isFocused)
        }
    }
    
    @ViewBuilder
    private func searchResults(_ results: [MapSearchResult], availableSize: CGSize) -> some View {
        if results.isEmpty == false {
            let maxHeight = searchResultsMaxHeight(in: availableSize)
            if CGFloat(results.count) * MapSearchLayout.resultRowHeight <= maxHeight {
                resultsList(results)
                    .mapGlassPanel()
            } else {
                ScrollView {
                    resultsList(results)
                }
                .frame(maxHeight: maxHeight, alignment: .bottom)
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
        let selectedDisplayText = isSearchFocused ? nil : searchResetControlState.selectedDisplayText
        
        return HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            ZStack(alignment: .leading) {
                TextField("Search solar systems, constellations, or regions", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isSearchFocused)
                    .opacity(selectedDisplayText == nil ? 1 : 0)
                
                if let selectedDisplayText {
                    Text(selectedDisplayText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(.primary)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFocused = true
            }
            
            if searchResetControlState.isVisible {
                Button {
                    resetSearchSelection()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .tint(.primary)
                .accessibilityLabel(hasSearchSelection ? "Reset search selection" : "Clear search")
            }
            
            if isSearchFocused {
                keyboardDismissButton
            }
        }
        .padding(.horizontal, 14)
        .frame(height: MapSearchLayout.searchFieldHeight)
        .mapGlassPanel()
    }

    private var characterVisibilityButton: some View {
        Button {
            showCharacterMarkers.toggle()
        } label: {
            Image(systemName: showCharacterMarkers ? "person.3.fill" : "person.3")
        }
        .accessibilityLabel(showCharacterMarkers ? "Hide characters" : "Show characters")
    }
    
    private func resetSearchSelection() {
        searchText = ""
        scene?.resetSelectionHighlight()
        hasSearchSelection = false
        selectedSearchResultTitle = nil
    }
    
    private func updateSearchFocus(_ isFocused: Bool) {
        searchText = searchResetControlState.searchTextAfterFocusChange(isFocused: isFocused)
    }
    
    private var keyboardDismissButton: some View {
        Button {
            isSearchFocused = false
        } label: {
            Image(systemName: "keyboard.chevron.compact.down")
                .imageScale(.medium)
                .frame(width: MapSearchLayout.searchControlSize, height: MapSearchLayout.searchControlSize)
        }
        .foregroundStyle(.primary)
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
    
    private func searchResultsMaxHeight(in availableSize: CGSize) -> CGFloat {
        let availableHeight =
            availableSize.height
            - MapSearchLayout.topSafeAreaInsetAllowance
            - MapSearchLayout.searchFieldHeight
            - MapSearchLayout.stackSpacing
            - MapSearchLayout.bottomPadding
        
        guard availableHeight.isFinite else {
            return MapSearchLayout.resultRowHeight
        }
        
        return max(MapSearchLayout.resultRowHeight, availableHeight)
    }
    
    private func attemptInitialFocusIfNeeded() {
        guard didApplyInitialFocus == false,
              let scene,
              selectionConfiguration != nil else {
            return
        }
        // Defer to the next runloop to ensure SpriteView is attached and laid out
        DispatchQueue.main.async {
            guard let scene = self.scene else { return }
            let isFiniteSize = self.viewportSize.width.isFinite && self.viewportSize.height.isFinite && self.viewportSize.width > 0 && self.viewportSize.height > 0
            let validViewport: CGSize? = isFiniteSize ? self.viewportSize : nil
            self.configureSelectionOverlays(in: scene)
            if self.focusOnSelection(in: scene, viewportSize: validViewport) {
                self.didApplyInitialFocus = true
            }
        }
    }
    
}

private struct MapSafeAreaIgnoringModifier: ViewModifier {

    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.ignoresSafeArea()
        } else {
            content
        }
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

}

private struct MapSystemDetailsView: View {

    @Environment(\.dismiss) private var dismiss

    let details: ECKMapSystemDetails
    let logoSource: ECKSolarSystemImageSource?

    var body: some View {
        Form {
            Section("System") {
                detailRow(title: "Name", value: details.name)
                detailRow(title: "Security", value: details.security)
                detailRow(title: "Region", value: details.regionName)
                detailRow(title: "Constellation", value: details.constellationName)

                if let sovereigntyName = details.sovereigntyName {
                    sovereigntyRow(name: sovereigntyName)
                }
            }

            if details.characters.isEmpty == false {
                Section("Characters") {
                    ForEach(details.characters) { character in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(characterStatusColor(character.isOnline))
                                .frame(width: 8, height: 8)
                            
                            Text(character.name)
                            
                            Spacer()
                        }
                    }
                }
            }

            Section("NPC Stations") {
                if details.stations.isEmpty {
                    Text("No NPC stations in this system.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(details.stations) { station in
                        stationRow(station)
                    }
                }
            }
        }
        .navigationTitle(details.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        LabeledContent(title, value: value)
    }

    private func stationRow(_ station: ECKStation) -> some View {
        HStack(spacing: 10) {
            if let imageSource = station.imageSource {
                ECImage(id: imageSource.id, category: imageSource.category)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }

            Text(station.stationName ?? "Unknown Station")
        }
    }

    private func sovereigntyRow(name: String) -> some View {
        HStack(spacing: 12) {
            Text("Sovereignty")

            Spacer()

            if let logoSource {
                ECImage(id: logoSource.id, category: logoSource.category)
                    .frame(width: 28, height: 28)
            }

            Text(name)
                .multilineTextAlignment(.trailing)
        }
    }

    private func characterStatusColor(_ isOnline: Bool?) -> Color {
        switch isOnline {
        case .some(true):
            return .green
        case .some(false):
            return .secondary
        case .none:
            return .blue
        }
    }

}

private extension ColorScheme {

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .dark:
            return .dark
        case .light:
            return .light
        @unknown default:
            return .unspecified
        }
    }

}

#Preview {
    MapView()
}

