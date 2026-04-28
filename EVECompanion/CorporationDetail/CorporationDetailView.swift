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
    @StateObject var contractManager: ECKContractManager
    @StateObject var marketOrderManager: ECKMarketOrderManager
    @StateObject var industryJobsManager: ECKIndustryJobManager
    
    init(corporation: ECKAuthenticatedCorporation) {
        self.corporation = corporation
        self._contractManager = StateObject(wrappedValue: .init(corporation: corporation))
        self._marketOrderManager = StateObject(wrappedValue: .init(corporation: corporation))
        self._industryJobsManager = StateObject(wrappedValue: .init(corporation: corporation))
    }
    
    var body: some View {
        List {
            Section {
                AuthenticatedCorporationCell(
                    corporation: corporation,
                    allowsNavigation: false
                )
            }
            
            Section("Wallet Divisions") {
                walletDivisionSection
            }
            
            Section("Finance") {
                row(for: .marketOrders)
                row(for: .contracts)
            }
            
            Section("Industry") {
                row(for: .industryJobs)
            }
        }
        .navigationTitle(corporation.publicCorpInfo?.name ?? "")
        .refreshable {
            await corporation.loadWalletDivisions()
        }
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
            return .contracts(manager: contractManager)
        case .marketOrders:
            return .marketOrders(manager: marketOrderManager)
        case .industryJobs:
            return .industryJobs(manager: industryJobsManager)
        }
    }
    
    @ViewBuilder
    private var walletDivisionSection: some View {
        switch corporation.walletDivisionsLoadingState {
        case .ready,
             .reloading:
            if let walletDivisions = corporation.walletDivisions,
               walletDivisions.isEmpty == false {
                ForEach(walletDivisions) { division in
                    HStack {
                        Text(division.name)
                        
                        Spacer()
                        
                        Text("\(ECFormatters.iskLong(division.balance)) ISK")
                            .multilineTextAlignment(.trailing)
                    }
                }
            } else {
                Text("No wallet division balances available.")
                    .foregroundStyle(.secondary)
            }
            
        case .loading:
            HStack {
                ProgressView()
                Text("Loading wallet divisions...")
                    .foregroundStyle(.secondary)
            }
            
        case .error(let error):
            ErrorView(error: error) {
                await corporation.loadWalletDivisions()
            }
        }
    }
}

#Preview {
    CoordinatorView(initialScreen: .corporationDetail(.dummy))
}
