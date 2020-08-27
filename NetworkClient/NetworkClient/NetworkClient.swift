//
//  NetworkClient.swift
//  NetworkClient
//
//  Created by Jonathan Sahoo on 1/8/20.
//  Copyright © 2020 Jonathan Sahoo. All rights reserved.
//

import Foundation
import Network
import ObjectMapper

public typealias Parameters = [String: Any]
public typealias DecodableRequestHandler<T> = ((T?, URLResponse?, Error?) -> Void)

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public struct HTTPBody {

    public enum Format {
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

    public let data: Data?
    public let dictionaryRepresentation: [String: Any]?
    public let format: Format

    /// Initialize a JSON HTTP body from the given parameters
    public init(json: [String: Any]) {
        self.dictionaryRepresentation = json
        self.format = .applicationJSON
        self.data = try? JSONSerialization.data(withJSONObject: json)
    }

    /// Initialize a Form URL Encoded HTTP body from the given parameters
    public init(formURLEncodedParameters: [String: Any]) {
        self.dictionaryRepresentation = formURLEncodedParameters
        self.format = .applicationXWWWFormURLEncoded
        self.data = formURLEncodedParameters.map({"\($0.key)=\($0.value)"}).joined(separator: "&").data(using: .utf8)
    }

    /// Initialize a JSON HTTP body by serializing the given encodable object
    public init<T: Encodable>(encodable object: T) throws {
        self.data = try? JSONEncoder().encode(object)
        self.format = .applicationJSON
        self.dictionaryRepresentation = nil
    }

    /// Initialize a HTTP body from the given data and format
    init(data: Data, format: Format) throws {
        self.dictionaryRepresentation = nil
        self.format = format
        self.data = data
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

public struct ResponseMetadata {

    /// The URL request sent to the server.
    public var request: URLRequest?

    /// The server's response to the URL request.
    public var response: HTTPURLResponse?

    /// The data returned by the server.
    public var data: Data?

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

    // TODO: Support custom sessions, sessions with certificate pinning
    fileprivate static let session = URLSession(configuration: .default)
    
    public static func initialize() {
        guard !hasBeenInitialized else { return }
        networkMonitor.pathUpdateHandler = { path in
            hasNetworkConnection = path.status == .satisfied
        }
        networkMonitor.start(queue: DispatchQueue(label: "NWPathMonitor"))
        hasBeenInitialized = true
    }

    /// If your APIs use the same base URL, you can use this closure to set your base URL. You can then use `NetworkRequest.init(path:_)` to construct all of your requests which will automatically construct the full URL using this base URL and the path given to the initializer. **NOTE**: This property **MUST** be set before using `NetworkRequest.init(path:_)` otherwise a fatal error will be thrown.
    ///
    /// We use a closure so that the base URL can be determined at execution time, i.e. to support dynamic base URLs that change based on the current environment.
    /// - Warning: This property **MUST** be set before using `NetworkRequest.init(path:_)` otherwise a fatal error will be thrown.
    public static var baseURL: (() -> String)!


    /// If you'd like to override the default response handling logic, set this property to your custom response handling logic.
    ///
    /// All network requests regardless of the deserialized return type utilize the same response handling logic. By default they are handled with the default response handling logic. You can override the default response handling logic by setting this property to your own custom response handling logic.
    public static var customResponseHandler: ((NetworkRequest, ResponseMetadata, Data?, URLResponse?, Error?) -> (Swift.Result<Data, Error>, ResponseMetadata))?
}

public class NetworkRequest {

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
    /// - Requires: `NetworkClient.baseURL` **MUST** be set otherwise a fatal error will be thrown.
    public convenience init(path: String,
                            method: HTTPMethod = .get,
                            queryParameters: Parameters? = nil,
                            body: HTTPBody? = nil,
                            headers: [String: String]? = nil,
                            validStatusCodes: [Int] = HTTPStatusCodes.successes) {
        self.init(url: NSString.path(withComponents: [NetworkClient.baseURL(), path]), method: method, queryParameters: queryParameters, body: body, headers: headers, validStatusCodes: validStatusCodes)
    }

    /// Executes a network request and returns the raw data from the response.
    ///
    /// This is where the actual network request for _all_ `NetworkRequest.responseXXX` functions are performed. All other `NetworkRequest.responseXXX` utilize this function for common response handling (i.e. validation, high-level error handling, etc.) before being deserialized to the appropriate type.
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

        if let body = body, let data = body.data {
            urlRequest.addValue(body.format.headerValue, forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = data
        }

        headers?.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }
        metadata.request = urlRequest

        // MARK: Execute Request

        guard NetworkClient.hasNetworkConnection else {
            completion(.failure(NetworkError.noNetworkConnection), metadata)
            return
        }

        NetworkClient.session.dataTask(with: urlRequest) { (data, urlResponse, error) in
            // If a custom response handler has been set, use it instead of the default (below)
            if let customResponseHandler = NetworkClient.customResponseHandler {
                let (result, metadata) = customResponseHandler(self, metadata, data, urlResponse, error)
                completion(result, metadata)
                return
            }

            // Default Response Handler

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

extension NetworkRequest {

    /// Executes a network request and deserializes the response to a BaseMappable-conforming object.
    public func responseMappable<T: BaseMappable>(completion: @escaping ((Result<T, Error>, ResponseMetadata?) -> Void)) {

        responseJSON { result, metadata in
            switch result {
            case .success(let json):
                if let mappable = T.self as? Mappable.Type {
                    guard let json = json as? [String: Any], let object = mappable.init(JSON: json) as? T else {
                        completion(.failure(NetworkError.deserializationFailure), metadata)
                        return
                    }
                    completion(.success(object), metadata)
                } else if let immutableMappable = T.self as? ImmutableMappable.Type {
                    guard let json = json as? [String: Any] else {
                        completion(.failure(NetworkError.deserializationFailure), metadata)
                        return
                    }
                    do {
                        guard let object = try immutableMappable.init(JSON: json) as? T else {
                            completion(.failure(NetworkError.deserializationFailure), metadata)
                            return
                        }
                        completion(.success(object), metadata)
                    } catch {
                        completion(.failure(error), metadata)
                    }
                } else {
                    completion(.failure(NetworkError.deserializationFailure), metadata)
                }
            case .failure(let error):
                completion(.failure(error), metadata)
            }
        }
    }

    /// Executes a network request and deserializes the response to an array of BaseMappable-conforming object.
    public func responseMappableArray<T: BaseMappable>(completion: @escaping ((Result<[T], Error>, ResponseMetadata?) -> Void)) {

        responseJSON { result, metadata in
            switch result {
            case .success(let json):
                guard let json = json as? [[String: Any]] else {
                    completion(.failure(NetworkError.deserializationFailure), metadata)
                    return
                }

                if let _ = T.self as? Mappable.Type {
                    completion(.success(Mapper<T>().mapArray(JSONArray: json)), metadata)
                } else if let immutableMappable = T.self as? ImmutableMappable.Type {
                    // We have to manually transform the JSON array to ImmutableMappable array due to an issue with not being able to force ObjectMapper to use the `mapArray` function specific to ImmutableMappable
                    let mappedArray = json.compactMap { (jsonElement) in
                        return try? immutableMappable.init(JSON: jsonElement)
                    } as? [T] ?? [T]()
                    completion(.success(mappedArray), metadata)
                } else {
                    completion(.success(Mapper<T>().mapArray(JSONArray: json)), metadata)
                }
            case .failure(let error):
                completion(.failure(error), metadata)
            }
        }
    }
}
