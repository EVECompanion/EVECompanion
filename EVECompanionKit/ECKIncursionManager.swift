//
//  ECKIncursionManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.06.24.
//

public import Combine

public class ECKIncursionManager: ObservableObject {
    
    @Published public var loadingState: ECKLoadingState = .loading
    @Published public var incursions: [ECKIncursion] = []
    
    public init() { }
    
    @MainActor
    public func loadIncursions() async {
        if incursions.isEmpty {
            loadingState = .loading
        } else {
            loadingState = .reloading
        }
        
        do {
            let resource = ECKIncursionsResource()
            self.incursions = try await ECKWebService().loadResource(resource: resource).response
            self.loadingState = .ready
        } catch {
            logger.error("Error loading incursions \(error)")
            self.loadingState = .error
        }
    }
    
}
