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

    /// Executes a network request that returns Data.
    func responseData() -> Promise<Data> {
        return Promise { seal in
            responseData { result, metadata in
                switch result {
                case .success(let data):
                    return seal.fulfill(data)
                case .failure(let error):
                    return seal.reject(error)
                }
            }
        }

//        return responseDataWithMetadata().then { data, _ -> Promise<Data> in
//            return .value(data)
//        }
    }

    /// Executes a network request that returns Data.
    func responseDataWithMetadata() -> Promise<(Data, ResponseMetadata?)> {
        return Promise { seal in
            responseData { result, metadata in
                switch result {
                case .success(let data):
                    return seal.fulfill((data, metadata))
                case .failure(let error):
                    return seal.reject(error)
                }
            }
        }
    }

    /// Executes a network request that returns Void.
    func requestVoid() -> Promise<Void> {
        return Promise { seal in
            responseVoid { result, metadata in
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
    func requestVoidWithMetadata() -> Promise<(Void, ResponseMetadata?)> {
        return Promise { seal in
            responseVoid { result, metadata in
                switch result {
                case .success:
                    return seal.fulfill(((), metadata))
                case .failure(let error):
                    return seal.reject(error)
                }
            }
        }
    }

    /// Executes a network request that returns Void.
    func requestJSON() -> Promise<Void> {
        return Promise { seal in
            responseVoid { result, metadata in
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
    func requestVoidWithMetadata() -> Promise<(Void, ResponseMetadata?)> {
        return Promise { seal in
            responseVoid { result, metadata in
                switch result {
                case .success:
                    return seal.fulfill(((), metadata))
                case .failure(let error):
                    return seal.reject(error)
                }
            }
        }
    }
}

#endif
