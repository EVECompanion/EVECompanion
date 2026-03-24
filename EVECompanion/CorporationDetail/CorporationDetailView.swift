//
//  CorporationDetailView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 29.11.25.
//

import SwiftUI
import EVECompanionKit

struct CorporationDetailView: View {
    
    @ObservedObject private var corporation: ECKAuthenticatedCorporation
    
    init(corporation: ECKAuthenticatedCorporation) {
        self.corporation = corporation
    }
    
    var body: some View {
        List {
            Section {
                AuthenticatedCorporationCell(corporation: corporation)
            }
            
            Section("Finance") {
                row(for: .marketOrders)
                row(for: .contracts)
            }
        }
        .navigationTitle(corporation.publicCorpInfo?.name ?? "")
    }
    
    @ViewBuilder
    func row(for row: CorporationDetailRowType) -> some View {
        NavigationLink(value: destination(for: row)) {
            HStack(content: {
                Image(row.image)
                    .resizable()
                    .frame(width: 50, height: 50)
                VStack(alignment: .leading) {
                    Text(row.title)
                    
                    if let secondaryText = row.secondaryText {
                        Text(secondaryText)
                            .foregroundStyle(Color.secondary)
                    }
                }
                
            })
        }
    }
    
    func destination(for row: CorporationDetailRowType) -> AppScreen {
        switch row {
        case .contracts:
            return .corpContracts(manager: .init(character: corporation.authenticatingCharacter))
        case .marketOrders:
            return .corpMarketOrders(corporation)
        }
    }
}

#Preview {
    CoordinatorView(initialScreen: .corporationDetail(.dummy))
}
