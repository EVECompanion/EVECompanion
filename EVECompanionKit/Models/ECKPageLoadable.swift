//
//  ECKPageLoadable.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 04.04.26.
//

public import Combine

public protocol ECKPageLoadable: ObservableObject {
    associatedtype Element: Identifiable
    
    @MainActor
    var elements: [Element] { get }
    
    @MainActor
    var hasNextPage: Bool { get }
    
    @MainActor
    func reload() async
    
    @MainActor
    func loadNextPage() async throws
}
