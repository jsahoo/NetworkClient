//
//  NetworkClient+PromiseKit.swift
//  NetworkClient
//
//  Created by Jonathan Sahoo on 7/1/20.
//  Copyright © 2020 Jonathan Sahoo. All rights reserved.
//

#if canImport(PromiseKit)

import Foundation
import PromiseKit

extension NetworkRequest {

    /// Executes a network request and returns the raw data from the response.
    func responseData() -> Promise<Data> {
        return responseDataWithMetadata().then { data, _ -> Promise<Data> in
            return .value(data)
        }.recover { error -> Promise<Data> in
            // Re-throw the underlying error and exclude response metadata
            throw (error as? PromiseNetworkError)?.error ?? error
        }
    }

    /// Executes a network request and returns the raw data from the response.
    func responseDataWithMetadata() -> Promise<(Data, ResponseMetadata?)> {
        return Promise { seal in
            responseData { result, metadata in
                switch result {
                case .success(let data):
                    return seal.fulfill((data, metadata))
                case .failure(let error):
                    return seal.reject(PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and returns Void.
    func responseVoid() -> Promise<Void> {
        return responseVoidWithMetadata().then { void, _ -> Promise<Void> in
            return .value(void)
        }.recover { error -> Promise<Void> in
            // Re-throw the underlying error and exclude response metadata
            throw (error as? PromiseNetworkError)?.error ?? error
        }
    }

    /// Executes a network request and returns Void.
    func responseVoidWithMetadata() -> Promise<(Void, ResponseMetadata?)> {
        return Promise { seal in
            responseVoid { result, metadata in
                switch result {
                case .success:
                    return seal.fulfill(((), metadata))
                case .failure(let error):
                    return seal.reject(PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    func responseJSON() -> Promise<Any> {
        return responseJSONWithMetadata().then { json, _ -> Promise<Any> in
            return .value(json)
        }.recover { error -> Promise<Any> in
            // Re-throw the underlying error and exclude response metadata
            throw (error as? PromiseNetworkError)?.error ?? error
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    func responseJSONWithMetadata() -> Promise<(Any, ResponseMetadata?)> {
        return Promise { seal in
            responseJSON { result, metadata in
                switch result {
                case .success(let json):
                    return seal.fulfill((json, metadata))
                case .failure(let error):
                    return seal.reject(PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    func responseDecodable<T: Decodable>() -> Promise<T> {
        return responseDecodableWithMetadata().then { object, _ -> Promise<T> in
            return .value(object)
        }.recover { error -> Promise<T> in
            // Re-throw the underlying error and exclude response metadata
            throw (error as? PromiseNetworkError)?.error ?? error
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    func responseDecodableWithMetadata<T: Decodable>() -> Promise<(T, ResponseMetadata?)> {
        return Promise { seal in
            responseDecodable { (result: Swift.Result<T, Error>, metadata: ResponseMetadata?) in
                switch result {
                case .success(let object):
                    return seal.fulfill((object, metadata))
                case .failure(let error):
                    return seal.reject(PromiseNetworkError(error: error, responseMetadata: metadata))
                }
            }
        }
    }
}

struct PromiseNetworkError: Error {
    var error: Error
    var responseMetadata: ResponseMetadata?
}

#endif
