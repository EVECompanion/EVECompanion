//
//  MailFeedbackView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import Foundation
import MessageUI
import SwiftUI
import EVECompanionKit

struct MailFeedbackView: UIViewControllerRepresentable {
    
    @Binding var includeDiagnostics: Bool
    @Binding var isShowing: Bool
    @Binding var result: Result<MFMailComposeResult, any Error>?

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {

        @Binding var isShowing: Bool
        @Binding var result: Result<MFMailComposeResult, any Error>?
        var zipFileURL: URL?

        init(isShowing: Binding<Bool>,
             result: Binding<Result<MFMailComposeResult, any Error>?>) {
            _isShowing = isShowing
            _result = result
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: (any Error)?) {
            defer {
                isShowing = false
            }
            guard error == nil else {
                self.result = .failure(error!)
                return
            }
            self.result = .success(result)
            
            DispatchQueue.global(qos: .background).async {
                if let zipFileURL = self.zipFileURL {
                    do {
                        try FileManager.default.removeItem(at: zipFileURL)
                        self.zipFileURL = nil
                    } catch {
                        logger.error("Cannot remove log zip file at URL \(zipFileURL)")
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(isShowing: $isShowing,
                           result: $result)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailFeedbackView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(["contact@evecompanion.app"])
        vc.setSubject("Feedback EVECompanion")
        
        if includeDiagnostics {
            context.coordinator.zipFileURL = logger.zipLogs()

            guard let zipFileURL = context.coordinator.zipFileURL else {
                return vc
            }

            let zipData: Data

            do {
                zipData = try Data(contentsOf: zipFileURL)
            } catch {
                logger.error("Error while reading content of log zip: \(error.localizedDescription)")
                return vc
            }
            
            vc.addAttachmentData(zipData, mimeType: "application/octet-stream", fileName: zipFileURL.lastPathComponent)
        }
        
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: UIViewControllerRepresentableContext<MailFeedbackView>) {

    }
}
