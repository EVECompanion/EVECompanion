//
//  ECKWebService.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation

class ECKWebService {
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    static var tokenCodingUserInfoKey: CodingUserInfoKey {
        return CodingUserInfoKey(rawValue: "token")!
    }
    
    let timeout = TimeInterval.fromSeconds(seconds: 15)
    
    static let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        return URLSession(configuration: configuration)
    }()
    
    init() { }
    
    @MainActor
    func loadResource(resource: ECKWebResource<ECKEmptyResponse>) async throws -> (response: ECKEmptyResponse, headers: [AnyHashable: Any]) {
        do {
            return try await self.handleResource(resource: resource)
        } catch ECKWebError.emptyResponse {
            return (response: ECKEmptyResponse(), headers: [:])
        } catch {
            throw error
        }
    }
    
    @MainActor
    func loadResource<DecodeTo>(resource: ECKWebResource<ECKOptionalResponse<DecodeTo>>) async throws -> (response: DecodeTo?, headers: [AnyHashable: Any]) where DecodeTo: Decodable {
        do {
            let response = try await self.handleResource(resource: resource)
            return (response: response.response.response,
                    headers: response.headers)
        } catch ECKWebError.statusCode(let statusCode, let data) {
            if statusCode == 404 {
                return (response: nil, headers: [:])
            } else {
                throw ECKWebError.statusCode(statusCode, data)
            }
        } catch {
            throw error
        }
    }
    
    @MainActor
    func loadResource<DecodeTo>(resource: ECKWebResource<DecodeTo>) async throws -> (response: DecodeTo, headers: [AnyHashable: Any]) where DecodeTo: Decodable {
        return try await handleResource(resource: resource)
    }
    
    private func handleResource<DecodeTo>(resource: ECKWebResource<DecodeTo>) async throws -> (response: DecodeTo, headers: [AnyHashable: Any]) where DecodeTo: Decodable {
        guard let url = resource.url else {
            logger.error("Resource \(resource) does not have a valid URL")
            throw ECKWebError.unknownError
        }
        
        guard await resource.tokenContainsRequiredScopes else {
            logger.error("Resource \(resource) does not have the required scopes.")
            throw ECKWebError.insufficientScopes
        }
        
        let fetchedData = try await self.loadData(url: url, resource: resource)
        
        if fetchedData.response.isEmpty {
            throw ECKWebError.emptyResponse
        }
        
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                let decoder = self.decoder
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let result = try decoder.decode(DecodeTo.self, from: fetchedData.response)
                        continuation.resume(returning: (response: result, headers: fetchedData.headers))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            return result
            
        } catch ECKWebError.statusCode(let statusCode, let data) {
            if statusCode == 403 {
                let tokenExpiredResponse = try decoder.decode(ECKTokenExpired.self, from: data)
                if tokenExpiredResponse.error == "token is expired" {
                    await resource.token?.markAccessTokenExpired()
                }
            }
            
            throw ECKWebError.statusCode(statusCode, data)
        } catch {
            if DecodeTo.self != ECKEmptyResponse.self {
                logger.error("Error while decoding data to \(DecodeTo.self): \(error.localizedDescription) data: \(String(data: fetchedData.response, encoding: .utf8) ?? "")")
            }
            throw error
        }
    }
    
    private func loadData<DecodeTo>(url: URL, resource: ECKWebResource<DecodeTo>) async throws -> (response: Data, headers: [AnyHashable: Any]) {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                var request = URLRequest(url: url, timeoutInterval: timeout)
                
                request.httpMethod = resource.method.rawValue
                
                for header in resource.headers {
                    request.addValue(header.value, forHTTPHeaderField: header.key)
                }
                
                let userAgent = "\(ECKAppInfo.bundleId)/\(ECKAppInfo.version) (contact@evecompanion.app; +https://github.com/EVECompanion/EVECompanion; eve:EVECompanion DotApp)"
                request.addValue(userAgent,
                                 forHTTPHeaderField: "User-Agent")
                
                if let token = resource.token {
                    guard token.isValid else {
                        continuation.resume(throwing: ECKAPIError.tokenInvalid)
                        return
                    }
                    
                    if token.isExpired {
                        do {
                            try await refreshToken(oldToken: token)
                        } catch {
                            logger.error("Error while refreshing token for \(token.characterName): \(error)")
                            continuation.resume(throwing: ECKAPIError.tokenRefresh)
                            return
                        }
                    }
                    
                    decoder.userInfo[Self.tokenCodingUserInfoKey] = token
                    request.addValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
                }
                
                if let body = resource.body {
                    if let data = body as? Data {
                         request.httpBody = data
                    } else {
                        let data = try? encoder.encode(body)
                        request.httpBody = data
                        request.addValue("application/json",
                                         forHTTPHeaderField: "Content-Type")
                    }
                }
                
                let body = request.httpBody
                let resourceDescription = String(describing: resource)
                let characterId = resource.token?.characterId
                logger.info("Loading data from URL \(url)")
                let dataTask = Self.urlSession.dataTask(with: request) { data, response, error in
                    if let error = error {
                        logger.error("Error while loading resource \(resourceDescription): \(error.localizedDescription)")
                        continuation.resume(throwing: ECKWebError.connectionError)
                        return
                    }
                    
                    guard let response = response as? HTTPURLResponse else {
                        logger.error("Cannot cast \(String(describing: response)) to HTTPURLResponse")
                        continuation.resume(throwing: ECKWebError.unknownError)
                        return
                    }
                    
                    guard let data = data else {
                        logger.warning("Received empty data, statuscode: \(String(describing: response.statusCode))")
                        continuation.resume(throwing: ECKWebError.emptyResponse)
                        return
                    }
                    
                    guard response.statusCode <= 299 else {
                        logger.error("Received status code \(response.statusCode) for \(url). Character: \(String(describing: characterId)). Request: \(String(describing: String(decoding: body ?? Data(), as: UTF8.self))) Response: \(String(decoding: data, as: UTF8.self))")
                        continuation.resume(throwing: ECKWebError.statusCode(response.statusCode, data))
                        return
                    }
                    
                    continuation.resume(returning: (response: data, headers: response.allHeaderFields))
                }
                
                dataTask.resume()
            }
        }
        
    }
    
    @MainActor
    private func refreshToken(oldToken: ECKToken) async throws {
        if let task = oldToken.refreshTask {
            try await task.value
            return
        }

        let task: Task<Void, any Error> = Task { @MainActor in
            try await performTokenRefresh(token: oldToken)
        }
        
        oldToken.refreshTask = task

        do {
            try await task.value
        } catch {
            throw error
        }
    }
    
    @MainActor
    private func performTokenRefresh(token: ECKToken) async throws {
        let task: Task<Void, any Error> = Task { @MainActor in
            let resource = ECKTokenRefreshResource(token: token, clientId: ECKConstants.clientId)
            do {
                let newToken = try await loadResource(resource: resource)
                token.updateToken(accessToken: newToken.response.accessToken,
                                  refreshToken: newToken.response.refreshToken)
            } catch ECKWebError.statusCode(let statusCode, let data) {
                if statusCode == 400 {
                    let tokenError = try decoder.decode(ECKTokenRefreshError.self, from: data)
                    if tokenError.error == "invalid_grant" {
                        token.markAsInvalid()
                    }
                }
                
                throw ECKWebError.statusCode(statusCode, data)
            } catch {
                logger.error("Error refreshing token: \(error)")
            }
            
            token.refreshTask = nil
        }
        
        token.refreshTask = task
        
        try await task.value
    }
    
}
