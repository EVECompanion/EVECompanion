//
//  SDEUpdateView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 01.08.24.
//

import SwiftUI
import EVECompanionKit

struct SDEUpdateView: View {
    
    enum Mode {
        case required
        case update
        
        var title: String {
            switch self {
            case .required:
                return "Database download required"
                
            case .update:
                return "Database update available"
                
            }
        }
        
        func subtitle(fileSize: Double) -> String {
            switch self {
            case .required:
                return "To use this app, a database download (approximately \(ECFormatters.sdeSize(fileSize))) containing items, skills and other data is required. Do you want to perform this download now?"
                
            case .update:
                return "A database update (approximately \(ECFormatters.sdeSize(fileSize))) containing new items, skills and other data is available. Do you want to download this update now?"
                
            }
        }
        
        var foregroundColor: Color {
            switch self {
                
            case .required:
                return .red
                
            case .update:
                return .yellow
                
            }
        }
    }
    
    enum UpdateState: Equatable {
        case info
        case downloading(progess: CGFloat)
        case success
        case error
    }
    
    @Environment(\.dismiss) var dismiss
    
    let mode: Mode
    @State var state: UpdateState = .info
    @ObservedObject var sdeUpdater: ECKSDEUpdater
    
    var showsSkipButton: Bool {
        if mode == .update {
            switch state {
                
            case .success,
                 .downloading:
                return false
                
            case .error,
                 .info:
                return true
                
            }
        } else {
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch state {
                    
                case .info:
                    infoView
                    
                case .error:
                    errorView
                    
                case .downloading(progess: let progress):
                    progressView(text: "Downloading...", progress: progress)
                    
                case .success:
                    successView

                }
                
            }
            .padding(.horizontal, 20)
            .animation(.spring, value: state)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .toolbar(content: {
                if showsSkipButton {
                    ToolbarItem {
                        Button(action: {
                            dismiss()
                        }, label: {
                            Text("Skip")
                        })
                    }
                }
            })
        }
        .interactiveDismissDisabled(state != .success)
    }
    
    @ViewBuilder
    var infoView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 20)
            
            Text(mode.title)
                .multilineTextAlignment(.center)
                .font(.title)
                .fontWeight(.bold)
            
            Spacer()
                .frame(height: 40)
            
            Image(systemName: "square.and.arrow.down.fill")
                .font(.system(size: 80))
                .foregroundStyle(mode.foregroundColor)
            
            Spacer()
                .frame(height: 40)
            
            Text(mode.subtitle(fileSize: sdeUpdater.fileSize))
                .multilineTextAlignment(.center)
                .font(.title3)
            
            Spacer()
                .frame(height: 20)
            
            Button(action: {
                performDownload()
            }, label: {
                Text("Start download")
                    .font(.title3)
            })
            
            Spacer()
        }
    }
    
    @ViewBuilder
    func progressView(text: String, progress: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 20)
            
            Text(text)
                .multilineTextAlignment(.center)
                .font(.title)
                .fontWeight(.bold)
            
            Spacer()
                .frame(height: 40)
            
            ZStack {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.green, style: StrokeStyle(
                        lineWidth: 15,
                        lineCap: .round
                    ))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring, value: progress)
                    .frame(width: 160, height: 160)
                
                Text("\(Int(progress * 100))%")
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    var errorView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 20)
            
            Text("Database download failed")
                .multilineTextAlignment(.center)
                .font(.title)
                .fontWeight(.bold)
            
            Spacer()
                .frame(height: 40)
            
            Image(systemName: "xmark.circle")
                .font(.system(size: 200))
                .foregroundStyle(.red)
            
            Spacer()
                .frame(height: 40)
            
            Text("The database download failed, do you want to try again?")
                .multilineTextAlignment(.center)
                .font(.title3)
            
            Spacer()
                .frame(height: 20)
            
            Button(action: {
                performDownload()
            }, label: {
                Text("Retry")
                    .font(.title3)
            })
            
            Spacer()
        }
    }
    
    @ViewBuilder
    var successView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 20)
            
            Text("Database download successful")
                .multilineTextAlignment(.center)
                .font(.title)
                .fontWeight(.bold)
            
            Spacer()
                .frame(height: 40)
            
            Image(systemName: "checkmark.circle")
                .font(.system(size: 200))
                .foregroundStyle(.green)
            
            Spacer()
                .frame(height: 40)
            
            Text("The database download was successful.")
                .multilineTextAlignment(.center)
                .font(.title3)
            
            Spacer()
                .frame(height: 20)
            
            Button {
                dismiss()
            } label: {
                Text("Close")
            }
            
            Spacer()
        }
    }
    
    func performDownload() {
        Task { @MainActor in
            do {
                self.state = .downloading(progess: 0)
                try await sdeUpdater.performSDEUpdate(downloadProgress: { progress in
                    self.state = .downloading(progess: progress)
                })
                
                self.state = .success
            } catch {
                self.state = .error
            }
        }
    }
    
}

#Preview("Download Required") {
    Color.red
        .sheet(isPresented: .constant(true), content: {
            SDEUpdateView(mode: .required,
                          sdeUpdater: .init())
        })
}

#Preview("Optional Update") {
    Color.red
        .sheet(isPresented: .constant(true), content: {
            SDEUpdateView(mode: .update,
                          sdeUpdater: .init())
        })
}

#Preview("Downloading") {
    Color.red
        .sheet(isPresented: .constant(true), content: {
            SDEUpdateView(mode: .required,
                          state: .downloading(progess: 0.3),
                          sdeUpdater: .init())
        })
}

#Preview("Error") {
    Color.red
        .sheet(isPresented: .constant(true), content: {
            SDEUpdateView(mode: .required,
                          state: .error,
                          sdeUpdater: .init())
        })
}

#Preview("Success") {
    Color.red
        .sheet(isPresented: .constant(true), content: {
            SDEUpdateView(mode: .required,
                          state: .success,
                          sdeUpdater: .init())
        })
}
