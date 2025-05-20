//
//  ContractListCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 13.05.24.
//

import SwiftUI
import EVECompanionKit

struct ContractListCell: View {
    
    @ObservedObject var contract: ECKContract
    
    var body: some View {
        VStack(alignment: .leading) {
            if let title = contract.title, title.isEmpty == false {
                Text(title)
                    .font(.title2)
                
                Spacer()
                    .frame(height: 10)
            }
            
            HStack(alignment: .top) {
                Text(contract.type.title)
                    .font(.title3)
                Spacer()
                Text(contract.availability.title)
            }
            
            Spacer()
                .frame(height: 10)
            
            Text("Issued on \(ECFormatters.dateFormatter(date: contract.dateIssued))")
            
            if contract.status == .outstanding {
                Text("Expires on \(ECFormatters.dateFormatter(date: contract.dateExpired))")
            }
            
            if contract.type == .courier,
               let dateAccepted = contract.dateAccepted {
                Text("Accepted on \(ECFormatters.dateFormatter(date: dateAccepted))")
            }
            
            HStack {
                Text(contract.status.title)
                if let dateCompleted = contract.dateCompleted {
                    Text(ECFormatters.dateFormatter(date: dateCompleted))
                }
                Spacer()
            }
            
            Spacer()
                .frame(height: 10)
            
            if let startSolarSystem = contract.startLocation.solarSystem,
               let endSolarSystem = contract.endLocation.solarSystem,
               contract.type == .courier {
                Text("\(startSolarSystem.solarSystemName) >> \(endSolarSystem.solarSystemName)")
            } else if let startLocationName = $contract.startLocation.stationName.wrappedValue {
                Text(startLocationName)
            }
        }
        .foregroundStyle(contract.status.foregroundColor)
    }
    
}

#Preview {
    List {
        ContractListCell(contract: .dummyCourierFailed)
        ContractListCell(contract: .dummyCourierCompleted)
        ContractListCell(contract: .dummyCourierOutstanding)
        ContractListCell(contract: .dummyCourierInProgress)
        ContractListCell(contract: .dummyItemExchangeFinished)
        ContractListCell(contract: .dummyItemExchangeOutstanding)
    }
    
}
