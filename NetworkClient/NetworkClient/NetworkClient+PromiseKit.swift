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

extension NetworkClient {

    /// Executes a network request that returns Data.
    public static func requestData(url: String,
                                   method: HTTPMethod = .get,
                                   queryParameters: Parameters? = nil,
                                   body: HTTPBody? = nil,
                                   headers: [String: String]? = nil,
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes) -> Promise<Data> {

        return Promise { seal in
            requestData(url: url, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes) { result in
                switch result {
                case .success(let data):
                    return seal.fulfill(data)
                case .failure(let error):
                    return seal.reject(error)
                }
            }
        }
    }

    /// Executes a network request that returns Data.
    public static func requestData(baseURL: String? = baseURL?(),
                                   path: String,
                                   method: HTTPMethod = .get,
                                   queryParameters: Parameters? = nil,
                                   body: HTTPBody? = nil,
                                   headers: [String: String]? = nil,
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes) -> Promise<Data> {

        return Promise { seal in
            requestData(baseURL: baseURL, path: path, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes) { result in
                switch result {
                case .success(let data):
                    return seal.fulfill(data)
                case .failure(let error):
                    return seal.reject(error)
                }
            }
        }
    }

    /// Executes a network request that returns Void.
    public static func requestVoid(url: String,
                                   method: HTTPMethod = .get,
                                   queryParameters: Parameters? = nil,
                                   body: HTTPBody? = nil,
                                   headers: [String: String]? = nil,
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes) -> Promise<Void> {

        return Promise { seal in
            requestVoid(url: url, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes) { result in
                switch result {
                case .success:
                    return seal.fulfill(())
                case .failure(let error):
                    return seal.reject(error)
                }
            }
        }
    }

    /// Executes a network request that returns Void.
    public static func requestVoid(baseURL: String? = baseURL?(),
                                   path: String,
                                   method: HTTPMethod = .get,
                                   queryParameters: Parameters? = nil,
                                   body: HTTPBody? = nil,
                                   headers: [String: String]? = nil,
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes) -> Promise<Void> {

        return Promise { seal in
            requestVoid(baseURL: baseURL, path: path, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes) { result in
                switch result {
                case .success:
                    return seal.fulfill(())
                case .failure(let error):
                    return seal.reject(error)
                }
            }
        }
    }

    /// Executes a network request that returns JSON.
    public static func requestJSON(url: String,
                                   method: HTTPMethod = .get,
                                   queryParameters: Parameters? = nil,
                                   body: HTTPBody? = nil,
                                   headers: [String: String]? = nil,
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes) -> Promise<Any> {

        return Promise { seal in
            requestJSON(url: url, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes) { result in
                switch result {
                case .success(let data):
                    return seal.fulfill(data)
                case .failure(let error):
                    return seal.reject(error)
                }
            }
        }
    }

    /// Executes a network request that returns JSON.
    public static func requestJSON(baseURL: String? = baseURL?(),
                                   path: String,
                                   method: HTTPMethod = .get,
                                   queryParameters: Parameters? = nil,
                                   body: HTTPBody? = nil,
                                   headers: [String: String]? = nil,
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes) -> Promise<Any> {

        return Promise { seal in
            requestJSON(baseURL: baseURL, path: path, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes) { result in
                switch result {
                case .success(let data):
                    return seal.fulfill(data)
                case .failure(let error):
                    return seal.reject(error)
                }
            }
        }
    }

    /// Executes a network request that returns a Decodable object.
    public static func request<T: Decodable>(url: String,
                                             method: HTTPMethod = .get,
                                             queryParameters: Parameters? = nil,
                                             body: HTTPBody? = nil,
                                             headers: [String: String]? = nil,
                                             validStatusCodes: [Int] = HTTPStatusCodes.successes) -> Promise<T> {

        return Promise { seal in
            request(url: url, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes) { (result: Swift.Result<T, Error>) in
                switch result {
                case .success(let data):
                    return seal.fulfill(data)
                case .failure(let error):
                    return seal.reject(error)
                }
            }
        }
    }

    public static func request<T: Decodable>(baseURL: String? = baseURL?(),
                                             path: String,
                                             method: HTTPMethod = .get,
                                             queryParameters: Parameters? = nil,
                                             body: HTTPBody? = nil,
                                             headers: [String: String]? = nil,
                                             validStatusCodes: [Int] = HTTPStatusCodes.successes) -> Promise<T> {

        return Promise { seal in
            request(baseURL: baseURL, path: path, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes) { (result: Swift.Result<T, Error>) in
                switch result {
                case .success(let data):
                    return seal.fulfill(data)
                case .failure(let error):
                    return seal.reject(error)
                }
            }
        }
    }
}

#endif
