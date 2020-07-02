//
//  NetworkClient.swift
//  NetworkClient
//
//  Created by Jonathan Sahoo on 1/8/20.
//  Copyright © 2020 Jonathan Sahoo. All rights reserved.
//

import Foundation
import Network

public typealias Parameters = [String: Any]
public typealias DecodableRequestHandler<T> = ((T?, URLResponse?, Error?) -> Void)

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public enum HTTPBodyFormat {
    case applicationXWWWFormURLEncoded
    case applicationJSON
    
    var headerValue: String {
        switch self {
        case .applicationXWWWFormURLEncoded:
            return "application/x-www-form-urlencoded"
        case .applicationJSON:
            return "application/json"
        }
    }
}

public protocol HTTPBody { }

public struct HTTPBodyFromDictionary: HTTPBody {
    public var parameters: Parameters
    public var format: HTTPBodyFormat
    
    public init(parameters: Parameters, format: HTTPBodyFormat) {
        self.parameters = parameters
        self.format = format
    }
}

public struct HTTPBodyFromEncodable: HTTPBody {
    var data: Data
    
    public init<T: Encodable>(_ object: T) throws {
        self.data = try JSONEncoder().encode(object)
    }
}

public class HTTPStatusCodes {
    public static let informationals = [Int](100..<200)
    public static let successes = [Int](200..<300)
    public static let redirections = [Int](300..<400)
    public static let clientErrors = [Int](400..<500)
    public static let serverErrors = [Int](500..<600)
}

public enum NetworkError: Error {
    case noNetworkConnection
    case noResponse
    case missingBaseURL
    case invalidURL(url: String)
    case invalidResponse(response: HTTPURLResponse, data: Data?)
    case noData(response: HTTPURLResponse)
    case deserializationFailure
    
    public var statusCode: Int? {
        switch self {
        case .invalidResponse(let response, _), .noData(let response):
            return response.statusCode
        default:
            return nil
        }
    }
}

public struct HTTPError: Error {
    public var urlResponse: HTTPURLResponse
    public var statusCode: Int {
        urlResponse.statusCode
    }
}

public class NetworkClient {

    /// If many of your APIs share the same base URL, you can set the default base URL here through this closure and use the NetworkClient request functions that construct the URL from this base URL and the supplied path.
    ///
    /// We use a closure so that the base URL can be determined at execution time, i.e. to support dynamic base URLs that change based on the current environment.
    public static var baseURL: (() -> String)?
    
    private static let networkMonitor = NWPathMonitor()
    public private(set) static var hasNetworkConnection = true
    private static var hasBeenInitialized = false
    
    private static let session = URLSession(configuration: .default)
    
    public static func initialize() {
        networkMonitor.pathUpdateHandler = { path in
            hasNetworkConnection = path.status == .satisfied
        }
        networkMonitor.start(queue: DispatchQueue(label: "NWPathMonitor"))
        hasBeenInitialized = true
    }


    /// Executes a network request that returns Data.
    ///
    /// This is where the actual network request for all NetworkClient request functions is performed. All other NetworkClient request functions utilize this function for making the actual network request.
    public static func requestData(url urlString: String,
                                   method: HTTPMethod = .get,
                                   queryParameters: Parameters? = nil,
                                   body: HTTPBody? = nil,
                                   headers: [String: String]? = nil,
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes,
                                   completion: @escaping ((Result<Data, Error>) -> Void)) {
        
        guard hasBeenInitialized else {
            fatalError("NetworkClient has not been initialized. Call NetworkClient.initialize() before performing any other functions.")
        }
        
        guard hasNetworkConnection else {
            completion(.failure(NetworkError.noNetworkConnection))
            return
        }
        
        // MARK: Build Request

        guard var urlComponents = URLComponents(string: urlString) else {
            completion(.failure(NetworkError.invalidURL(url: urlString)))
            return
        }
        
        if let queryParameters = queryParameters {
            urlComponents.queryItems = queryParameters.map( { URLQueryItem(name: $0.0, value: "\($0.1)") } )
        }
        
        guard let url = urlComponents.url else {
            completion(.failure(NetworkError.invalidURL(url: urlString)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        
        if let body = body as? HTTPBodyFromDictionary {
            urlRequest.addValue(body.format.headerValue, forHTTPHeaderField: "Content-Type")
            switch body.format {
            case .applicationXWWWFormURLEncoded:
                urlRequest.httpBody = body.parameters.map({"\($0.key)=\($0.value)"}).joined(separator: "&").data(using: .utf8)
            case .applicationJSON:
                do {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body.parameters)
                } catch {
                    completion(.failure(error))
                    return
                }
            }
        } else if let body = body as? HTTPBodyFromEncodable {
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = body.data
        }
        
        headers?.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        // MARK: Execute Request
        
        session.dataTask(with: urlRequest) { (data, urlResponse, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let urlResponse = urlResponse as? HTTPURLResponse else {
                completion(.failure(NetworkError.noResponse))
                return
            }
                
            guard validStatusCodes.contains(urlResponse.statusCode) else {
                completion(.failure(NetworkError.invalidResponse(response: urlResponse, data: data)))
                return
            }
            
            guard let unwrappedData = data else {
                completion(.failure(NetworkError.noData(response: urlResponse)))
                return
            }
            
            completion(.success(unwrappedData))
        }.resume()
    }

    /// Executes a network request that returns Data.
    public static func requestData(baseURL: String? = baseURL?(),
                                   path: String,
                                   method: HTTPMethod = .get,
                                   queryParameters: Parameters? = nil,
                                   body: HTTPBody? = nil,
                                   headers: [String: String]? = nil,
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes,
                                   completion: @escaping ((Result<Data, Error>) -> Void)) {

        guard let baseURL = baseURL else {
            completion(.failure(NetworkError.missingBaseURL))
            return
        }

        let urlString = NSString.path(withComponents: [baseURL, path])

        requestData(url: urlString, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes, completion: completion)
    }

    /// Executes a network request that returns Void.
    public static func requestVoid(url: String,
                                   method: HTTPMethod = .get,
                                   queryParameters: Parameters? = nil,
                                   body: HTTPBody? = nil,
                                   headers: [String: String]? = nil,
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes,
                                   completion: @escaping ((Result<Void, Error>) -> Void)) {

        requestData(url: url, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes) { result in

            // `result` will _never_ be `success`. We have to examine the error to determine if the request was successful or not

            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                if case NetworkError.noData = error {
                    completion(.success(()))
                } else {
                    completion(.failure(error))
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
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes,
                                   completion: @escaping ((Result<Void, Error>) -> Void)) {

        guard let baseURL = baseURL else {
            completion(.failure(NetworkError.missingBaseURL))
            return
        }

        let url = NSString.path(withComponents: [baseURL, path])

        requestVoid(url: url, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes, completion: completion)
    }

    /// Executes a network request that returns JSON.
    public static func requestJSON(url: String,
                                   method: HTTPMethod = .get,
                                   queryParameters: Parameters? = nil,
                                   body: HTTPBody? = nil,
                                   headers: [String: String]? = nil,
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes,
                                   completion: @escaping ((Result<Any, Error>) -> Void)) {

        requestData(url: url, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes) { result in

            switch result {
            case .success(let data):
                do {
                    completion(.success(try JSONSerialization.jsonObject(with: data)))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
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
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes,
                                   completion: @escaping ((Result<Any, Error>) -> Void)) {

        guard let baseURL = baseURL else {
            completion(.failure(NetworkError.missingBaseURL))
            return
        }

        let url = NSString.path(withComponents: [baseURL, path])

        requestJSON(url: url, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes, completion: completion)
    }

    /// Executes a network request that returns a Decodable object.
    public static func request<T: Decodable>(url: String,
                                             method: HTTPMethod = .get,
                                             queryParameters: Parameters? = nil,
                                             body: HTTPBody? = nil,
                                             headers: [String: String]? = nil,
                                             validStatusCodes: [Int] = HTTPStatusCodes.successes,
                                             completion: @escaping ((Result<T, Error>) -> Void)) {

        requestData(url: url, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes) { result in

            switch result {
            case .success(let data):
                do {
                    completion(.success(try JSONDecoder().decode(T.self, from: data)))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Executes a network request that returns a Decodable object.
    public static func request<T: Decodable>(baseURL: String? = baseURL?(),
                                             path: String,
                                             method: HTTPMethod = .get,
                                             queryParameters: Parameters? = nil,
                                             body: HTTPBody? = nil,
                                             headers: [String: String]? = nil,
                                             validStatusCodes: [Int] = HTTPStatusCodes.successes,
                                             completion: @escaping ((Result<T, Error>) -> Void)) {

        guard let baseURL = baseURL else {
            completion(.failure(NetworkError.missingBaseURL))
            return
        }

        let url = NSString.path(withComponents: [baseURL, path])

        request(url: url, method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes, completion: completion)
    }
}
