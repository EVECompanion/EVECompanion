//
//  ECKServerStatusManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 24.05.25.
//

public import Combine

public class ECKServerStatusManager: ObservableObject {
    
    @Published public var loadingState: ECKLoadingState = .loading
    @Published public var status: ECKServerStatus?
    
    private var lastEtag: String?
    
    public init() {
        Task {
            await loadServerStatus()
        }
    }
    
    func loadServerStatus() async {
        repeat {
            await updateServerStatus()
            
            try? await Task.sleep(for: .seconds(60))
        } while(true)
    }
    
    @MainActor
    private func updateServerStatus() async {
        let resource = ECKServerStatusResource(etag: lastEtag)
        do {
            let response = try await ECKWebService().loadResource(resource: resource)
            self.lastEtag = ((response.headers["Etag"] ?? response.headers["ETag"]) as? String)
            self.status = response.response
            self.loadingState = .ready
        } catch {
            logger.error("Error while fetching server status: \(error)")
            loadingState = .error
        }
    }
    
}
