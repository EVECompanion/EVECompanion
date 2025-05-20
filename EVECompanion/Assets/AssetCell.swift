//
//  AssetCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 25.06.24.
//

import SwiftUI
import EVECompanionKit

struct AssetCell: View {
    
    let asset: ECKAsset
    @EnvironmentObject var coordinator: Coordinator
    
    var body: some View {
        HStack {
            HStack {
                ECImage(id: asset.item.typeId,
                        category: .types,
                        isBPC: asset.isBlueprintCopy)
                .frame(width: 40, height: 40)
                
                VStack(alignment: .leading) {
                    if let customName = asset.customName {
                        Text(customName)
                        Text(asset.formattedItemName)
                            .foregroundStyle(Color.secondary)
                    } else if asset.quantity > 1 {
                        HStack {
                            Text(asset.formattedItemName)
                            Spacer()
                            Text("\(asset.quantity)x")
                                .fontWeight(.bold)
                        }
                    } else {
                        Text(asset.formattedItemName)
                    }
                }
            }
            .onTapGesture {
                coordinator.push(screen: .item(asset.item))
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
}

#Preview {
    List {
        AssetCell(asset: .dummyAvatar)
    }
    .environmentObject(Coordinator(initialScreen: .assetList(manager: .init(character: .dummy, isPreview: true))))
}
