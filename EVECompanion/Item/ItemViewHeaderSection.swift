//
//  ItemViewHeaderSection.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 26.03.25.
//

import SwiftUI
import EVECompanionKit

struct ItemViewHeaderSection: View {
    
    let item: ECKItem
    
    var body: some View {
        Section {
            HStack {
                ECImage(id: item.typeId,
                        category: .types)
                .frame(width: 100,
                       height: 100)
                
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.title)
                    
                    Text("\(item.category) / \(item.group)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .listRowSeparator(.hidden)
            
            if let description = item.attributedDescription {
                AttributedTextView(description)
                    .listRowSeparator(.hidden)
            }
        }
    }
    
}

#Preview {
    List {
        ItemViewHeaderSection(item: .init(typeId: 11567))
    }
    .listStyle(.plain)
}
