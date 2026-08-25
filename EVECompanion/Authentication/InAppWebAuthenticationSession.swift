//
//  InAppWebAuthenticationSession.swift
//  EVECompanion
//
//  Created by Rida Amirini on 25.08.26.
//

import SwiftUI
import AuthenticationServices
import Combine

/// Runs the EVE SSO login inside an in-app web view instead of the system `WebAuthenticationSession`.
///
/// The system session honours universal links: When the Steam app is installed and the user picks
/// "Log in with Steam" on the SSO page, the Steam OpenID request is handed over to the Steam app,
/// which then continues in the default browser. The browser does not share the SSO session with the
/// authentication session, so the login can never make it back into the app
/// (https://github.com/EVECompanion/EVECompanion/issues/8).
///
/// A `WKWebView` never opens universal links on its own, so the complete flow - including the Steam
/// sign-in - stays inside the app and the callback URL can be intercepted.
///
/// Pending requests are presented by attaching `inAppWebAuthentication(_:)` to a view.
@MainActor
final class InAppWebAuthenticationSession: ObservableObject {
    
    /// A login that is waiting to be finished inside the in-app web view.
    @MainActor
    final class Request: Identifiable {
        
        let id = UUID()
        let url: URL
        let callbackURLScheme: String
        private var continuation: CheckedContinuation<URL, any Error>?
        
        init(url: URL,
             callbackURLScheme: String,
             continuation: CheckedContinuation<URL, any Error>) {
            self.url = url
            self.callbackURLScheme = callbackURLScheme
            self.continuation = continuation
        }
        
        /// Finishes the login with the callback URL the SSO redirected to.
        func complete(with callbackURL: URL) {
            continuation?.resume(returning: callbackURL)
            continuation = nil
        }
        
        /// Cancels the login. Does nothing if the request has already been finished.
        func cancel() {
            continuation?.resume(throwing: ASWebAuthenticationSessionError(.canceledLogin))
            continuation = nil
        }
        
    }
    
    /// The request that is currently presented, if any.
    @Published var request: Request?
    
    /// Whether the Steam app is installed.
    /// Requires the Steam URL schemes to be listed in `LSApplicationQueriesSchemes`.
    static var isSteamAppInstalled: Bool {
        ["steam://", "steammobile://"]
            .compactMap({ URL(string: $0) })
            .contains(where: { UIApplication.shared.canOpenURL($0) })
    }
    
    /// Authenticates using the system `webAuthenticationSession` unless the Steam app is installed.
    /// In that case the login is performed inside the in-app web view, which keeps the Steam sign-in
    /// from leaving the app.
    nonisolated func authenticate(using url: URL,
                                  callbackURLScheme: String,
                                  preferring webAuthenticationSession: WebAuthenticationSession) async throws -> URL {
        guard await Self.isSteamAppInstalled else {
            return try await webAuthenticationSession.authenticate(using: url, callbackURLScheme: callbackURLScheme)
        }
        
        return try await authenticate(using: url, callbackURLScheme: callbackURLScheme)
    }
    
    /// Authenticates inside the in-app web view and returns the callback URL.
    func authenticate(using url: URL, callbackURLScheme: String) async throws -> URL {
        request?.cancel()
        
        return try await withCheckedThrowingContinuation({ continuation in
            request = Request(url: url,
                              callbackURLScheme: callbackURLScheme,
                              continuation: continuation)
        })
    }
    
}

private struct InAppWebAuthenticationModifier: ViewModifier {
    
    @ObservedObject var session: InAppWebAuthenticationSession
    
    func body(content: Content) -> some View {
        content
            .sheet(item: $session.request, content: { request in
                InAppWebAuthenticationView(request: request)
            })
    }
    
}

extension View {
    
    /// Presents logins started via `InAppWebAuthenticationSession` in a sheet.
    func inAppWebAuthentication(_ session: InAppWebAuthenticationSession) -> some View {
        modifier(InAppWebAuthenticationModifier(session: session))
    }
    
}
