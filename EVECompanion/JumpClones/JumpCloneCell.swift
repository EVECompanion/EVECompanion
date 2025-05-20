//
//  JumpCloneCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 22.06.24.
//

import SwiftUI
import EVECompanionKit

struct JumpCloneCell: View {
    
    @ObservedObject var jumpClone: ECKJumpClone
    
    var body: some View {
        Section {
            if jumpClone.implants.isEmpty {
                Text("No implants")
            } else {
                ForEach(jumpClone.implants) { implant in
                    NavigationLink(value: AppScreen.item(implant)) {
                        HStack {
                            ECImage(id: implant.typeId,
                                    category: .types)
                            .frame(width: 40, height: 40)
                            
                            Text(implant.name)
                        }
                    }
                }
            }
        } header: {
            VStack(alignment: .leading) {
                Text(jumpClone.name ?? "Jump Clone")
                    .font(.headline)
                
                if let stationName = jumpClone.location.stationName {
                    Spacer()
                        .frame(height: 10)
                    
                    Text(stationName)
                }
            }
            
        }
        .animation(.spring, value: jumpClone.location.stationName)
    }
    
}

#Preview {
    NavigationStack {
        List {
            JumpCloneCell(jumpClone: .dummy)
        }
    }
}
