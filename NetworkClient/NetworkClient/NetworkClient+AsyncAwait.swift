//
//  NetworkClient+AsyncAwait.swift
//  NetworkClient
//
//  Created by Jonathan Sahoo on 12/22/21.
//  Copyright © 2021 Jonathan Sahoo. All rights reserved.
//

import Foundation

@available(iOS 13.0.0, *)
extension NetworkRequest {

    /// Executes a network request and returns the raw data from the response.
    public func responseData() async throws -> Data {
        do {
            return try await responseDataWithMetadata().0
        } catch {
            // Re-throw the underlying error and exclude response metadata
            throw (error as? PromiseNetworkError)?.error ?? error
        }
    }

    /// Executes a network request and returns the raw data from the response.
    public func responseDataWithMetadata() async throws -> (Data, ResponseMetadata?) {
        return try await withCheckedThrowingContinuation { continuation in
            responseData { result, metadata in
                switch result {
                case .success(let data):
                    continuation.resume(returning: (data, metadata))
                case .failure(let error):
                    continuation.resume(throwing: PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and returns Void.
    public func responseVoid() async throws -> Void {
        do {
            return try await responseVoidWithMetadata().0
        } catch {
            // Re-throw the underlying error and exclude response metadata
            throw (error as? PromiseNetworkError)?.error ?? error
        }
    }

    /// Executes a network request and returns Void.
    public func responseVoidWithMetadata() async throws -> (Void, ResponseMetadata?) {
        return try await withCheckedThrowingContinuation { continuation in
            responseVoid { result, metadata in
                switch result {
                case .success:
                    continuation.resume(returning: ((), metadata))
                case .failure(let error):
                    continuation.resume(throwing: PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    public func responseJSON() async throws -> Any {
        do {
            return try await responseJSONWithMetadata().0
        } catch {
            // Re-throw the underlying error and exclude response metadata
            throw (error as? PromiseNetworkError)?.error ?? error
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    public func responseJSONWithMetadata() async throws -> (Any, ResponseMetadata?) {
        return try await withCheckedThrowingContinuation { continuation in
            responseJSON { result, metadata in
                switch result {
                case .success(let json):
                    continuation.resume(returning: (json, metadata))
                case .failure(let error):
                    continuation.resume(throwing: PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    public func responseDecodable<T: Decodable>() async throws -> T {
        do {
            return try await responseDecodableWithMetadata().0
        } catch {
            // Re-throw the underlying error and exclude response metadata
            throw (error as? PromiseNetworkError)?.error ?? error
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    public func responseDecodableWithMetadata<T: Decodable>() async throws -> (T, ResponseMetadata?) {
        return try await withCheckedThrowingContinuation { continuation in
            responseDecodable { (result: Swift.Result<T, Error>, metadata: ResponseMetadata?) in
                switch result {
                case .success(let object):
                    continuation.resume(returning: (object, metadata))
                case .failure(let error):
                    continuation.resume(throwing: PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }
}

// MARK: - V2

/**
 I'm considering an alternative implementation where instead of having separate functions for returning just the data/object versus the data/obect with the metadata, creating a generic struct that always returns both. Below is the first pass implementation

 Should probably also create a struct for handling errors, similar to PromiseNetworkError, but more generic (not specifically tied to promises). Just call it NetworkError?
*/

public struct NetworkResponse<T> {
    public let object: T
    public let metadata: ResponseMetadata?

    /**
     The var name `object` isnt great since this can apply to so many things. One option is to make it private, and then create public getters called `data`, `json`, `decodedObject` that just return `object`. Although I suppose this could be weird cuz if you were expecting `data` to return Data and it returned something else, it'd be weird.

     Another idea is to create concrete subclasses like DataResponse, JSONResponse, VoidResponse, DecodableResponse and each of them then have their own var name. This is probably the most clear, it's just extra code. So, trade offs.
    */
}

@available(iOS 13.0.0, *)
extension NetworkRequest {
    /// Executes a network request and returns the raw data from the response.
    public func responseDataV2() async throws -> NetworkResponse<Data> {
        return try await withCheckedThrowingContinuation { continuation in
            responseData { result, metadata in
                switch result {
                case .success(let data):
                    continuation.resume(returning: .init(object: data, metadata: metadata))
                case .failure(let error):
                    continuation.resume(throwing: PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and returns Void.
    public func responseVoidV2() async throws -> NetworkResponse<Void> {
        return try await withCheckedThrowingContinuation { continuation in
            responseVoid { result, metadata in
                switch result {
                case .success:
                    continuation.resume(returning: .init(object: (), metadata: metadata))
                case .failure(let error):
                    continuation.resume(throwing: PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    public func responseJSONV2() async throws -> NetworkResponse<Any> {
        return try await withCheckedThrowingContinuation { continuation in
            responseJSON { result, metadata in
                switch result {
                case .success(let json):
                    continuation.resume(returning: .init(object: json, metadata: metadata))
                case .failure(let error):
                    continuation.resume(throwing: PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    public func responseDecodableV2<T: Decodable>() async throws -> NetworkResponse<T> {
        return try await withCheckedThrowingContinuation { continuation in
            responseDecodable { (result: Swift.Result<T, Error>, metadata: ResponseMetadata?) in
                switch result {
                case .success(let object):
                    continuation.resume(returning: .init(object: object, metadata: metadata))
                case .failure(let error):
                    continuation.resume(throwing: PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }
}

// MARK: - V3

/**
Okay here's the other possible option, creating concrete subclasses like DataResponse, JSONResponse, VoidResponse, DecodableResponse and each of them then have their own var name. This is probably the most clear, it's just extra code.
*/

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

@available(iOS 13.0.0, *)
extension NetworkRequest {
    /// Executes a network request and returns the raw data from the response.
    public func responseDataV3() async throws -> NetworkResponseData {
        return try await withCheckedThrowingContinuation { continuation in
            responseData { result, metadata in
                switch result {
                case .success(let data):
                    continuation.resume(returning: .init(data: data, metadata: metadata))
                case .failure(let error):
                    continuation.resume(throwing: PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and returns Void.
    public func responseVoidV3() async throws -> NetworkResponseVoid {
        return try await withCheckedThrowingContinuation { continuation in
            responseVoid { result, metadata in
                switch result {
                case .success:
                    continuation.resume(returning: .init(metadata: metadata))
                case .failure(let error):
                    continuation.resume(throwing: PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    public func responseJSONV3() async throws -> NetworkResponseJSON {
        return try await withCheckedThrowingContinuation { continuation in
            responseJSON { result, metadata in
                switch result {
                case .success(let json):
                    continuation.resume(returning: .init(json: json, metadata: metadata))
                case .failure(let error):
                    continuation.resume(throwing: PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    public func responseDecodableV3<T: Decodable>() async throws -> NetworkResponseDecodable<T> {
        return try await withCheckedThrowingContinuation { continuation in
            responseDecodable { (result: Swift.Result<T, Error>, metadata: ResponseMetadata?) in
                switch result {
                case .success(let object):
                    continuation.resume(returning: .init(decodableObject: object, metadata: metadata))
                case .failure(let error):
                    continuation.resume(throwing: PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }
}
