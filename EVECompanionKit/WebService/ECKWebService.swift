//
//  ECKWebService.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation

final class ECKWebService: Sendable {
    
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
    
    func loadResource(resource: ECKWebResource<ECKEmptyResponse>) async throws(ECKWebError) -> (response: ECKEmptyResponse, headers: [String: String]) {
        do {
            return try await self.handleResource(resource: resource)
        } catch ECKWebError.emptyResponse {
            return (response: ECKEmptyResponse(), headers: [:])
        } catch {
            throw error
        }
    }
    
    func loadResource<DecodeTo>(resource: ECKWebResource<ECKOptionalResponse<DecodeTo>>) async throws(ECKWebError) -> (response: DecodeTo?, headers: [String: String]) where DecodeTo: Decodable {
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
    
    func loadResource<DecodeTo>(resource: ECKWebResource<DecodeTo>) async throws(ECKWebError) -> (response: DecodeTo, headers: [String: String]) where DecodeTo: Decodable & Sendable {
        return try await handleResource(resource: resource)
    }
    
    private func handleResource<DecodeTo>(resource: ECKWebResource<DecodeTo>) async throws(ECKWebError) -> (response: DecodeTo, headers: [String: String]) where DecodeTo: Decodable & SendableMetatype {
        guard let url = resource.url else {
            logger.error("Resource \(resource) does not have a valid URL")
            throw ECKWebError.unknownError
        }
        
        guard await resource.tokenContainsRequiredScopes else {
            logger.error("Resource \(resource) does not have the required scopes.")
            throw ECKWebError.insufficientScopes
        }
        
        guard await resource.tokenContainsRequiredRoles else {
            logger.error("Resource \(resource) does not have the required corp roles.")
            throw ECKWebError.insufficientCorpRole(requiredRoles: resource.requiredCorpRoles)
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
                let tokenExpiredResponse = try? decoder.decode(ECKTokenExpired.self, from: data)
                if tokenExpiredResponse?.error == "token is expired" {
                    await resource.token?.markAccessTokenExpired()
                }
            }
            
            throw ECKWebError.statusCode(statusCode, data)
        } catch {
            if DecodeTo.self != ECKEmptyResponse.self {
                logger.error("Error while decoding data to \(DecodeTo.self): \(error) data: \(String(data: fetchedData.response, encoding: .utf8) ?? "")")
            }
            throw .decoding
        }
    }
    
    private func loadData<DecodeTo>(url: URL, resource: ECKWebResource<DecodeTo>) async throws(ECKWebError) -> (response: Data, headers: [String: String]) where DecodeTo: Decodable & SendableMetatype {
        do {
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
                            logger.error("Received status code \(response.statusCode) for \(url). Character: \(String(describing: characterId)). Request: \(String(describing: String(data: body ?? Data(), encoding: .utf8))) Response: \(String(data: data, encoding: .utf8) ?? "EMPTY")")
                            continuation.resume(throwing: ECKWebError.statusCode(response.statusCode, data))
                            return
                        }
                        
                        continuation.resume(returning: (response: data, headers: response.allHeaderFields as? [String: String] ?? [:]))
                    }
                    
                    dataTask.resume()
                }
            }
        } catch let error as ECKWebError {
            throw error
        } catch {
            logger.error("Error loading data: \(error)")
            throw .unknownError
        }
    }
    
    @ECKTokenActor
    internal func refreshToken(oldToken: ECKToken) async throws(ECKWebError) {
        let account = oldToken.storageAccount

        if let existingTask = ECKTokenActor.refreshTask(for: account) {
            let previousAccessToken = oldToken.accessToken
            let previousRefreshToken = oldToken.refreshToken
            do {
                try await existingTask.value
                guard !oldToken.isRemoved else {
                    throw ECKWebError.unknownError
                }

                let latestToken = ECKKeychain.getTokens(target: oldToken.tokenTarget).first(where: { $0.characterId == oldToken.characterId })
                if let latestToken {
                    oldToken.sync(from: latestToken)
                }

                let tokenChanged = oldToken.accessToken != previousAccessToken || oldToken.refreshToken != previousRefreshToken
                let storedTokenChanged = latestToken.map {
                    $0.accessToken != previousAccessToken || $0.refreshToken != previousRefreshToken
                } ?? false
                guard oldToken.isValid, tokenChanged || storedTokenChanged else {
                    throw ECKWebError.unknownError
                }
                return
            } catch let error as ECKWebError {
                throw error
            } catch {
                logger.error("Error refreshing token for \(account): \(error)")
                throw .unknownError
            }
        }

        let taskID = UUID()
        let task: Task<Void, any Error> = Task { @ECKTokenActor in
            defer {
                ECKTokenActor.clearRefreshTask(for: account, matching: taskID)
            }
            try await performTokenRefresh(token: oldToken)
        }
        
        ECKTokenActor.setRefreshTask(task, for: account, id: taskID)

        do {
            try await task.value
            guard !oldToken.isRemoved else {
                throw ECKWebError.unknownError
            }
        } catch let error as ECKWebError {
            throw error
        } catch {
            throw .unknownError
        }
    }
    
    @ECKTokenActor
    internal func performTokenRefresh(token: ECKToken) async throws {
        let expectedAccessToken = token.accessToken
        let expectedRefreshToken = token.refreshToken
        let resource = ECKTokenRefreshResource(token: token, clientId: ECKConstants.clientId)
        do {
            let newToken = try await loadResource(resource: resource)
            let updateResult = token.updateToken(
                accessToken: newToken.response.accessToken,
                refreshToken: newToken.response.refreshToken,
                replacingAccessToken: expectedAccessToken,
                refreshToken: expectedRefreshToken
            )
            if updateResult == .missing {
                throw ECKWebError.unknownError
            }
            if updateResult == .superseded, !token.isValid {
                throw ECKWebError.unknownError
            }
        } catch ECKWebError.statusCode(let statusCode, let data) {
            if statusCode == 400 {
                let tokenError = try? decoder.decode(ECKTokenRefreshError.self, from: data)
                if tokenError?.error == "invalid_grant" {
                    if syncIfNewerTokenExists(for: token) {
                        return
                    }
                    token.markAsInvalid()
                }
            }
            
            throw ECKWebError.statusCode(statusCode, data)
        } catch {
            logger.error("Error refreshing token: \(error)")
            throw error
        }
    }

    @ECKTokenActor
    internal func syncIfNewerTokenExists(for token: ECKToken) -> Bool {
        let currentTokens = ECKKeychain.getTokens(target: token.tokenTarget)
        guard let storedToken = currentTokens.first(where: { $0.characterId == token.characterId }),
              storedToken.refreshToken != token.refreshToken,
              storedToken.isValid else {
            return false
        }

        logger.info("Ignoring invalid_grant for stale refresh token \(token.characterId). Keychain already has newer valid token.")
        token.sync(from: storedToken)
        return true
    }
    
}
