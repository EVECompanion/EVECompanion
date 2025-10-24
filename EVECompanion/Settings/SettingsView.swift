//
//  SettingsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 12.05.24.
//

import SwiftUI
import EVECompanionKit
import PulseUI
import Kingfisher
import SwiftPackageListUI
import MessageUI

struct SettingsView: View {
    
    @StateObject var settingsManager: ECKSettingsManager = .init()
    @AppStorage(ECKDefaultKeys.isDemoModeEnabled.rawValue) var isDemoModeEnabled = false
    @AppStorage(ECKDefaultKeys.showDatesInUTC.rawValue) var showDatesInUTC = false
    @AppStorage(ECKDefaultKeys.localSDEVersion.rawValue) var databaseVersion: Int?
    
    @Binding var enableEmptySkillQueueNotifications: Bool
    @Binding var enableSkillCompletedNotifications: Bool
    
    @EnvironmentObject var notificationManager: ECKNotificationManager
    
    struct AlertIdentifier: Identifiable {
        enum Choice {
            case noMailConfiguredAlert
            case mailFeedbackAlert
            case deleteSDEAlert
        }

        var id: Choice
    }
    
    @State var includeLogDiagnostics: Bool = false
    @State var showMailFeedbackView: Bool = false
    @State var alertIdentifier: AlertIdentifier?
    @State var mailFeedbackResult: Result<MFMailComposeResult, any Error>?
    @State var showClearImageCacheConfirmation: Bool = false
    
    init() {
        _enableEmptySkillQueueNotifications = .init {
            return UserDefaults.standard.enableEmptySkillQueueNotifications
        } set: { newValue in
            UserDefaults.standard.enableEmptySkillQueueNotifications = newValue
        }
        
        _enableSkillCompletedNotifications = .init {
            return UserDefaults.standard.enableSkillCompletedNotifications
        } set: { newValue in
            UserDefaults.standard.enableSkillCompletedNotifications = newValue
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("General")) {
                Toggle("Show dates in EVE Time", isOn: $showDatesInUTC)
            }
            
            if let didGrantPushPermission = notificationManager.didGrantPermission {
                Section(header: Text("Push Notifications")) {
                    if didGrantPushPermission {
                        Toggle("Empty Skill Queue Warnings",
                               isOn: $enableEmptySkillQueueNotifications)
                        Toggle("Skill Completed Notification",
                               isOn: $enableSkillCompletedNotifications)
                    } else {
                        PushPermissionCTA(compact: true)
                    }
                }
            }
            
            Section(header: Text("Demo Mode"),
                    footer: Text("Enable demo mode to explore the app without logging in.")) {
                Toggle("Enable Demo Mode", isOn: $isDemoModeEnabled)
            }
            
            Section(header: Text("Feedback")) {
                Button(action: {
                    if MFMailComposeViewController.canSendMail() {
                        alertIdentifier = AlertIdentifier(id: .mailFeedbackAlert)
                    } else {
                        alertIdentifier = AlertIdentifier(id: .noMailConfiguredAlert)
                    }
                }, label: {
                    Text("Send Feedback")
                })
            }
            
            Section(header: Text("About")) {
                Link("Source Code", destination: URL(string: "https://github.com/EVECompanion")!)
            }
            
            Section(header: Text("Advanced")) {
                Button(action: {
                    showClearImageCacheConfirmation = true
                    KingfisherManager.shared.cache.clearCache()
                }, label: {
                    HStack {
                        Text("Clear image cache")
                        
                        Spacer()
                        
                        if showClearImageCacheConfirmation {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                        }
                    }
                })
                
                Button(action: {
                    alertIdentifier = AlertIdentifier(id: .deleteSDEAlert)
                }, label: {
                    Text("Reset database")
                })
            }
            
#if DEBUG
            Section(header: Text("Pulse")) {
                NavigationLink(destination: ConsoleView()) {
                    Text("Open Pulse UI")
                }
            }
#endif
            
            Section(content: {
                Link("Privacy Policy",
                     destination: URL(string: "https://www.iubenda.com/privacy-policy/31541547")!)
                NavigationLink {
                    AcknowledgmentsList()
                } label: {
                    Text("Acknowledgments")
                }
                
                Link("EVE Online accounts are managed by CCP Games. For account management or data removal requests, please contact CCP directly at https://support.eveonline.com/.",
                     destination: URL(string: "https://support.eveonline.com/")!)
            }, footer: {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ISK Donations are welcome. Character: \"EVECompanion DotApp\" in the \"EVECompanion DotApp Corporation\" (Ticker: [.APP.])")
                    
                    if let databaseVersion {
                        Text("Database Version: \(databaseVersion)")
                    }
                        
                    Text("\(ECKAppInfo.appName) \(ECKAppInfo.version), Build \(ECKAppInfo.build) by Jonas Schlabertz")
                }
            })
        }
        .animation(.spring, value: notificationManager.didGrantPermission)
        .navigationTitle("Settings")
        .sheet(isPresented: $showMailFeedbackView, content: {
            MailFeedbackView(includeDiagnostics: $includeLogDiagnostics,
                             isShowing: $showMailFeedbackView,
                             result: $mailFeedbackResult)
        })
        .alert(item: $alertIdentifier) { alert in
            switch alert.id {
            
            case .mailFeedbackAlert:
                Alert(title: Text("Include diagnostic data?"),
                      message: Text("To find software errors, diagnostic data is required. This data will only be used for troubleshooting the bugs that you report. Do you want to include diagnostic data?"),
                      primaryButton: .cancel(Text("Yes"), action: {
                    self.includeLogDiagnostics = true
                    self.showMailFeedbackView = true
                }),
                      secondaryButton: .destructive(Text("No"), action: {
                    self.includeLogDiagnostics = false
                    self.showMailFeedbackView = true
                }))
                
            case .noMailConfiguredAlert:
                Alert(title: Text("Cannot send mails"),
                      message: Text("Your system is not configured to send E-Mails. Please mail your feedback directly to contact@evecompanion.app"),
                      dismissButton: .default(Text("Ok")))
                
            case .deleteSDEAlert:
                Alert(title: Text("Database Reset"),
                      message: Text("You should only reset the database if you are having problems displaying things like items or skills. You will need to re-download the database after resetting it. Do you want to continue?"),
                      primaryButton: .cancel(),
                      secondaryButton: .destructive(Text("Reset"), action: {
                    ECKSDEManager.shared.removeSDEFile()
                }))
                
            }
        }
        .onChange(of: showClearImageCacheConfirmation) { newValue in
            if newValue {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)
                    showClearImageCacheConfirmation = false
                }
            }
        }
    }
    
}

#Preview {
    CoordinatorView(initialScreen: .settings)
}
