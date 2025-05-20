//
//  AssetsListView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 23.06.24.
//

import SwiftUI
import EVECompanionKit

struct AssetsListView: View {
    
    private struct StationSectionHeader: View {
        @StateObject var station: ECKStation
        
        var body: some View {
            Text(station.stationName ?? "")
                .font(.headline)
        }
    }
    
    @ObservedObject var assetManager: ECKAssetManager
    
    var body: some View {
        Group {
            switch assetManager.loadingState {
            case .ready,
                 .reloading:
                List(assetManager.assetLocations) { assetLocation in
                    section(for: assetLocation)
                }
                .refreshable {
                    await assetManager.loadAssets()
                }
                .searchable(text: $assetManager.searchText)
                
            case .loading:
                ProgressView()
                
            case .error:
                RetryButton {
                    await assetManager.loadAssets()
                }
                
            }
        }
        .navigationTitle("Assets")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    func section(for location: ECKAssetLocation) -> some View {
        Section {
            ForEach(assetManager.assets?[location] ?? []) { asset in
                OutlineGroup(asset, children: \.children) { asset in
                    AssetCell(asset: asset)
                }
            }
        } header: {
            switch location {
            case .station(let station):
                StationSectionHeader(station: station)
            case .solarSystem(let solarSystem):
                Text(solarSystem.solarSystemName)
            case .item:
                EmptyView()
            case .other:
                EmptyView()
            case .unknown:
                Text("Unknown Location")
            }
        }
    }
    
}

#Preview {
    AssetsListView(assetManager: .init(character: .dummy, isPreview: true))
}
