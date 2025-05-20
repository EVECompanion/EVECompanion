//
//  CharacterLogoutButton.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 10.04.25.
//

import Foundation
import SwiftUI
import EVECompanionKit

struct CharacterLogoutButton: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var character: ECKCharacter
    @State var showLogoutConfirmationDialog: Bool = false

    var body: some View {
        Button(action: {
            showLogoutConfirmationDialog = true
        }, label: {
            Text("Logout")
        })
        .alert(isPresented: $showLogoutConfirmationDialog, content: {
            Alert(title: Text("Do you really want to logout \(character.name)?"),
                  primaryButton: .cancel({
                self.showLogoutConfirmationDialog = false
            }),
                  secondaryButton: .destructive(Text("Logout"), action: {
                character.remove()
                dismiss()
            }))
        })
    }
}
