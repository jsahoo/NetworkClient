//
//  NetworkClient+AsyncAwait.swift
//  NetworkClient
//
//  Created by Jonathan Sahoo on 12/22/21.
//  Copyright © 2021 Jonathan Sahoo. All rights reserved.
//

import Foundation

public struct NetworkResponseData {
    public let data: Data
    public let metadata: ResponseMetadata?
}

public struct NetworkResponseVoid {
    public let metadata: ResponseMetadata?
}

public struct NetworkResponseJSON {
    public let json: Any
    public let metadata: ResponseMetadata?
}

public struct NetworkResponseDecodable<T: Decodable> {
    public let decodableObject: T
    public let metadata: ResponseMetadata?
}

public struct NetworkResponseError: Error {
    public let error: Error
    public let responseMetadata: ResponseMetadata?
}

@available(iOS 13.0.0, *)
extension NetworkRequest {
    /// Executes a network request and returns the raw data from the response.
    @discardableResult
    public func responseData() async throws -> NetworkResponseData {
        return try await withCheckedThrowingContinuation { continuation in
            responseData { result, metadata in
                switch result {
                case .success(let data):
                    continuation.resume(returning: .init(data: data, metadata: metadata))
                case .failure(let error):
                    continuation.resume(throwing: NetworkResponseError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and returns Void.
    @discardableResult
    public func responseVoid() async throws -> NetworkResponseVoid {
        return try await withCheckedThrowingContinuation { continuation in
            responseVoid { result, metadata in
                switch result {
                case .success:
                    continuation.resume(returning: .init(metadata: metadata))
                case .failure(let error):
                    continuation.resume(throwing: NetworkResponseError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    @discardableResult
    public func responseJSON() async throws -> NetworkResponseJSON {
        return try await withCheckedThrowingContinuation { continuation in
            responseJSON { result, metadata in
                switch result {
                case .success(let json):
                    continuation.resume(returning: .init(json: json, metadata: metadata))
                case .failure(let error):
                    continuation.resume(throwing: NetworkResponseError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    @discardableResult
    public func responseDecodable<T: Decodable>() async throws -> NetworkResponseDecodable<T> {
        return try await withCheckedThrowingContinuation { continuation in
            responseDecodable { (result: Swift.Result<T, Error>, metadata: ResponseMetadata?) in
                switch result {
                case .success(let object):
                    continuation.resume(returning: .init(decodableObject: object, metadata: metadata))
                case .failure(let error):
                    continuation.resume(throwing: NetworkResponseError(error: error, responseMetadata: metadata))
                }
            }
        }
    }
}
