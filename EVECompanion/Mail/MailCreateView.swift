//
//  MailCreateView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 19.05.24.
//

import SwiftUI
import EVECompanionKit

struct MailCreateView: View {
    
    let character: ECKCharacter
    @State var recipients: [ECKMailRecipient]
    
    var body: some View {
        NavigationStack {
            Text("Input something here.")
        }
    }
    
}
