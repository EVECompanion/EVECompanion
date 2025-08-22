//
//  CapitalNavigationShipPickerView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 12.03.25.
//

import SwiftUI
import EVECompanionKit

struct CapitalNavigationShipPickerView: View {
    
    @ObservedObject var manager: ECKCapitalNavigationManager
    let pickedShip: (ECKJumpCapableShip) -> Void
    @State var ships: [ECKJumpCapableShip] = []
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(manager.ships, id: \.groupName) { section in
                Section(section.groupName) {
                    ForEach(section.ships) { ship in
                        shipButton(ship: ship)
                    }
                }
            }
            .navigationTitle("Choose Your Ship")
        }
    }
    
    @ViewBuilder
    private func shipButton(ship: ECKJumpCapableShip) -> some View {
        Button {
            pickedShip(ship)
            dismiss()
        } label: {
            HStack {
                ECImage(id: ship.typeId, category: .types)
                    .frame(width: 40, height: 40)
                Text(ship.name)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CapitalNavigationShipPickerView(manager: .init()) { _ in
                return
            }
        }
}
