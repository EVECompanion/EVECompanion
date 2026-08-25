//
//  InAppWebAuthenticationView.swift
//  EVECompanion
//
//  Created by Rida Amirini on 25.08.26.
//

import SwiftUI
import WebKit
import EVECompanionKit

/// Sheet content that performs an `InAppWebAuthenticationSession.Request` inside a `WKWebView`.
struct InAppWebAuthenticationView: View {
    
    let request: InAppWebAuthenticationSession.Request
    
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = true
    @State private var loadingFailed: Bool = false
    @State private var loadAttempt: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AuthenticationWebView(url: request.url,
                                      callbackURLScheme: request.callbackURLScheme,
                                      loadAttempt: loadAttempt,
                                      isLoading: $isLoading,
                                      loadingFailed: $loadingFailed,
                                      onCallback: { callbackURL in
                    request.complete(with: callbackURL)
                    dismiss()
                })
                .ignoresSafeArea(edges: .bottom)
                
                if loadingFailed {
                    errorView
                } else if isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("EVE Online Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("Cancel")
                    })
                }
            })
        }
        .onDisappear {
            // Covers the cancel button as well as interactive dismissal.
            // Does nothing if the request has already been completed.
            request.cancel()
        }
    }
    
    @ViewBuilder
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            
            Text("The login page could not be loaded.")
                .multilineTextAlignment(.center)
                .font(.title3)
            
            Button(action: {
                loadingFailed = false
                isLoading = true
                loadAttempt += 1
            }, label: {
                Text("Retry")
                    .font(.title3)
            })
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
    
}

private struct AuthenticationWebView: UIViewRepresentable {
    
    let url: URL
    let callbackURLScheme: String
    /// Incremented to reload the login page after a failure.
    let loadAttempt: Int
    @Binding var isLoading: Bool
    @Binding var loadingFailed: Bool
    let onCallback: (URL) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        
        if context.coordinator.loadedAttempt != loadAttempt {
            context.coordinator.loadedAttempt = loadAttempt
            webView.load(URLRequest(url: url))
        }
    }
    
    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        
        /// `WebKitErrorDomain` code for "Frame load interrupted", reported after a navigation
        /// has been cancelled via `decidePolicyFor`. There is no public constant for it.
        private static let frameLoadInterruptedErrorCode = 102
        
        var parent: AuthenticationWebView
        var loadedAttempt: Int?
        
        init(parent: AuthenticationWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url,
                  let scheme = url.scheme?.lowercased() else {
                return .allow
            }
            
            if scheme == parent.callbackURLScheme.lowercased() {
                parent.onCallback(url)
                return .cancel
            }
            
            // Only regular web navigation may happen inside the web view. Anything else
            // (e.g. `steam://` links offered by the Steam login page) would open another app
            // and break the login flow.
            guard scheme == "http" || scheme == "https" || scheme == "about" else {
                return .cancel
            }
            
            return .allow
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
            handle(error)
        }
        
        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: any Error) {
            handle(error)
        }
        
        private func handle(_ error: any Error) {
            let nsError = error as NSError
            
            // Cancelled and interrupted frame loads are expected,
            // e.g. after intercepting the callback URL above.
            guard nsError.code != NSURLErrorCancelled,
                  nsError.code != Self.frameLoadInterruptedErrorCode else {
                return
            }
            
            logger.error("In-app web authentication failed to load \(parent.url): \(error.localizedDescription)")
            parent.isLoading = false
            parent.loadingFailed = true
        }
        
    }
    
}

