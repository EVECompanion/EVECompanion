//
//  UniverseView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 15.05.24.
//

import SwiftUI

struct UniverseView: View {
    
    var body: some View {
        List {
            row(for: .itemDatabase)
            row(for: .incursions)
            row(for: .sovereigntyCampaigns)
        }
        .navigationTitle("Universe")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    func row(for row: UniverseRowType) -> some View {
        NavigationLink(value: row.destination) {
            HStack(content: {
                Image(row.image)
                    .resizable()
                    .frame(width: 50, height: 50)
                Text(row.title)
            })
        }
    }
    
}

#Preview {
    CoordinatorView(initialScreen: .universe)
}
