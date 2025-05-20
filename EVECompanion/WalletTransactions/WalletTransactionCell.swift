//
//  WalletTransactionCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 26.05.24.
//

import SwiftUI
import EVECompanionKit
import Kingfisher

struct WalletTransactionCell: View {
    
    let entry: ECKWalletTransactionEntry
    
    var body: some View {
        NavigationLink(value: AppScreen.item(entry.item)) {
            HStack {
                ECImage(id: entry.item.typeId,
                        category: .types)
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading) {
                    Text("\(entry.quantity)x \(entry.item.name)")
                        .font(.headline)
                    
                    Spacer()
                        .frame(height: 10)
                    
                    Text("Price: \(ECFormatters.iskLong(entry.unitPrice)) ISK")
                    
                    HStack {
                        Text("Total:")
                        Text(ECFormatters.iskLong(entry.unitPrice * Double(entry.quantity) * (entry.isBuy ? -1 : 1)) + " ISK")
                            .foregroundStyle(entry.isBuy ? Color.red : Color.green)
                    }
                    
                    Text(ECFormatters.dateFormatter(date: entry.date))
                }
            }
        }
    }
}

#Preview {
    List {
        WalletTransactionCell(entry: .dummy1)
        WalletTransactionCell(entry: .dummy2)
    }
}
