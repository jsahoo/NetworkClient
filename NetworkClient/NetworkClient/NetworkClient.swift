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
    case invalidStatusCode(Int)
    case invalidResponse
    case noData
    case deserializationFailure
}

public struct HTTPError: Error {
    public var urlResponse: HTTPURLResponse
    public var statusCode: Int {
        urlResponse.statusCode
    }
}

public struct ResponseMetadata {

    /// The URL request sent to the server.
    public fileprivate(set) var request: URLRequest?

    /// The server's response to the URL request.
    public fileprivate(set) var response: HTTPURLResponse?

    /// The data returned by the server.
    public fileprivate(set) var data: Data?

    public init(request: URLRequest? = nil, response: HTTPURLResponse? = nil, data: Data? = nil) {
        self.request = request
        self.response = response
        self.data = data
    }
}

public class NetworkClient {

    private static let networkMonitor = NWPathMonitor()
    public private(set) static var hasNetworkConnection = true
    fileprivate static var hasBeenInitialized = false

    fileprivate static let session = URLSession(configuration: .default)
    
    public static func initialize() {
        guard !hasBeenInitialized else { return }
        networkMonitor.pathUpdateHandler = { path in
            hasNetworkConnection = path.status == .satisfied
        }
        networkMonitor.start(queue: DispatchQueue(label: "NWPathMonitor"))
        hasBeenInitialized = true
    }
}

public class NetworkRequest {

    public class var baseURL: String {
        return ""
    }

    public var url: String
    public var method: HTTPMethod = .get
    public var queryParameters: Parameters? = nil
    public var body: HTTPBody? = nil
    public var headers: [String: String]? = nil
    public var validStatusCodes: [Int] = HTTPStatusCodes.successes

    /// Initialize a NetworkRequest for the given URL.
    public init(url: String,
                method: HTTPMethod = .get,
                queryParameters: Parameters? = nil,
                body: HTTPBody? = nil,
                headers: [String: String]? = nil,
                validStatusCodes: [Int] = HTTPStatusCodes.successes) {
        self.url = url
        self.method = method
        self.queryParameters = queryParameters
        self.body = body
        self.headers = headers
        self.validStatusCodes = validStatusCodes
    }

    /// Initialize a NetworkRequest using the default base URL and the given path.
    public convenience init(path: String,
                            method: HTTPMethod = .get,
                            queryParameters: Parameters? = nil,
                            body: HTTPBody? = nil,
                            headers: [String: String]? = nil,
                            validStatusCodes: [Int] = HTTPStatusCodes.successes) {
        self.init(url: NSString.path(withComponents: [NetworkRequest.baseURL, path]), method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes)
    }

    /// Executes a network request and returns the raw data from the response.
    ///
    /// This is where the actual network request for all NetworkClient request functions is performed. All other NetworkClient request functions utilize this function for making the actual network request.
    public func responseData(completion: @escaping ((Swift.Result<Data, Error>, ResponseMetadata?) -> Void)) {

        NetworkClient.initialize()

        // MARK: Build Request

        guard var urlComponents = URLComponents(string: url) else {
            completion(.failure(NetworkError.invalidURL(url: url)), nil)
            return
        }

        if let queryParameters = queryParameters {
            urlComponents.queryItems = queryParameters.map( { URLQueryItem(name: $0.0, value: "\($0.1)") } )
        }

        let urlString = url
        guard let url = urlComponents.url else {
            completion(.failure(NetworkError.invalidURL(url: urlString)), nil)
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        var metadata = ResponseMetadata(request: urlRequest)

        if let body = body as? HTTPBodyFromDictionary {
            urlRequest.addValue(body.format.headerValue, forHTTPHeaderField: "Content-Type")
            switch body.format {
            case .applicationXWWWFormURLEncoded:
                urlRequest.httpBody = body.parameters.map({"\($0.key)=\($0.value)"}).joined(separator: "&").data(using: .utf8)
            case .applicationJSON:
                do {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body.parameters)
                } catch {
                    completion(.failure(error), metadata)
                    return
                }
            }
        } else if let body = body as? HTTPBodyFromEncodable {
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = body.data
        }

        headers?.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }
        metadata.request = urlRequest

        // MARK: Execute Request

        guard NetworkClient.hasNetworkConnection else {
            completion(.failure(NetworkError.noNetworkConnection), metadata)
            return
        }

        NetworkClient.session.dataTask(with: urlRequest) { (data, urlResponse, error) in
            metadata.data = data
            metadata.response = urlResponse as? HTTPURLResponse

            if let error = error {
                completion(.failure(error), metadata)
                return
            }

            guard let urlResponse = urlResponse as? HTTPURLResponse else {
                completion(.failure(NetworkError.noResponse), metadata)
                return
            }

            guard self.validStatusCodes.contains(urlResponse.statusCode) else {
                completion(.failure(NetworkError.invalidStatusCode(urlResponse.statusCode)), metadata)
                return
            }

            guard let unwrappedData = data else {
                completion(.failure(NetworkError.noData), metadata)
                return
            }

            completion(.success(unwrappedData), metadata)
        }.resume()
    }

    /// Executes a network request and returns Void.
    public func responseVoid(completion: @escaping ((Result<Void, Error>, ResponseMetadata?) -> Void)) {

        responseData { result, metadata in

            // `result` will _never_ be `success`. We have to examine the error to determine if the request was successful or not

            switch result {
            case .success:
                completion(.success(()), metadata)
            case .failure(let error):
                if case NetworkError.noData = error {
                    completion(.success(()), metadata)
                } else {
                    completion(.failure(error), metadata)
                }
            }
        }
    }

    /// Executes a network request and deserializes the response to JSON.
    public func responseJSON(completion: @escaping ((Result<Any, Error>, ResponseMetadata?) -> Void)) {

        responseData { result, metadata in
            switch result {
            case .success(let data):
                do {
                    completion(.success(try JSONSerialization.jsonObject(with: data)), metadata)
                } catch {
                    completion(.failure(error), metadata)
                }
            case .failure(let error):
                completion(.failure(error), metadata)
            }
        }
    }

    /// Executes a network request and deserializes the response to a Decodable object.
    public func responseDecodable<T: Decodable>(completion: @escaping ((Result<T, Error>, ResponseMetadata?) -> Void)) {

        responseData { result, metadata in
            switch result {
            case .success(let data):
                do {
                    completion(.success(try JSONDecoder().decode(T.self, from: data)), metadata)
                } catch {
                    completion(.failure(error), metadata)
                }
            case .failure(let error):
                completion(.failure(error), metadata)
            }
        }
    }
}
