//
//  LogoutButton.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 10.04.25.
//

import Foundation
import SwiftUI
import EVECompanionKit

struct LogoutButton: View {
    
    enum TargetValue {
        case character(name: String)
        case corp(name: String)
        
        var text: String {
            switch self {
            case .character(let name):
                "Do you really want to logout \(name)?"
            case .corp(let name):
                "Do you really want to logout the corporation \(name)?"
            }
        }
    }
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var character: ECKCharacter
    @State private var showLogoutConfirmationDialog: Bool = false
    let targetValue: TargetValue
    
    init(character: ECKCharacter, targetValue: TargetValue) {
        self.character = character
        self.targetValue = targetValue
    }
    
    var body: some View {
        Button(action: {
            showLogoutConfirmationDialog = true
        }, label: {
            Text("Logout")
        })
        .alert(isPresented: $showLogoutConfirmationDialog, content: {
            Alert(title: Text(targetValue.text),
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
