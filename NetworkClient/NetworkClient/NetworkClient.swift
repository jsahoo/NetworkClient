//
//  NetworkClient.swift
//  NetworkClient
//
//  Created by Jonathan Sahoo on 1/8/20.
//  Copyright © 2020 Jonathan Sahoo. All rights reserved.
//

import Foundation

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

public struct HTTPBody {
    var parameters: Parameters
    var format: HTTPBodyFormat
    
    public init(parameters: Parameters, format: HTTPBodyFormat) {
        self.parameters = parameters
        self.format = format
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
    case invalidURL
    case invalidStatusCode
    case noData
}

public class NetworkClient {
    
    private static let session = URLSession(configuration: .default)
    
    public static func requestData(url: String,
                                   method: HTTPMethod = .get,
                                   queryParameters: Parameters? = nil,
                                   body: HTTPBody? = nil,
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes,
                                   completion: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        
        // MARK: Build Request
        
        guard var urlComponents = URLComponents(string: url) else {
            completion(nil, nil, NetworkError.invalidURL)
            return
        }
        
        if let queryParameters = queryParameters {
            urlComponents.queryItems = queryParameters.map( { URLQueryItem(name: $0.0, value: "\($0.1)") } )
        }
        
        guard let url = urlComponents.url else {
            completion(nil, nil, NetworkError.invalidURL)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        
        if let body = body {
            urlRequest.addValue(body.format.headerValue, forHTTPHeaderField: "Content-Type")
            switch body.format {
            case .applicationXWWWFormURLEncoded:
                urlRequest.httpBody = body.parameters.map({"\($0.key)=\($0.value)"}).joined(separator: "&").data(using: .utf8)
            case .applicationJSON:
                do {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body.parameters)
                } catch {
                    completion(nil, nil, error)
                    return
                }
            }
        }
        
        // MARK: Execute Request
        
        session.dataTask(with: urlRequest) { (data, urlResponse, error) in
            if let error = error {
                completion(nil, urlResponse, error)
                return
            }
                
            guard let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode, validStatusCodes.contains(statusCode) else {
                completion(nil, urlResponse, NetworkError.invalidStatusCode)
                return
            }
            
            guard let data = data else {
                completion(nil, urlResponse, NetworkError.noData)
                return
            }
            
            completion(data, urlResponse, nil)
        }.resume()
    }
    
    public static func requestVoid(url: String,
                                   method: HTTPMethod = .get,
                                   queryParameters: Parameters? = nil,
                                   body: HTTPBody? = nil,
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes,
                                   completion: @escaping ((URLResponse?, Error?) -> Void)) {
        
        requestData(url: url, method: method, queryParameters: queryParameters, body: body, validStatusCodes: validStatusCodes) { (data, urlResponse, error) in
            
            if let error = error {
                if case NetworkError.noData = error {
                    completion(urlResponse, nil)
                } else {
                    completion(urlResponse, error)
                }
            } else {
                completion(urlResponse, nil)
            }
        }
    }
    
    public static func requestJSON(url: String,
                                   method: HTTPMethod = .get,
                                   queryParameters: Parameters? = nil,
                                   body: HTTPBody? = nil,
                                   validStatusCodes: [Int] = HTTPStatusCodes.successes,
                                   completion: @escaping ((Any?, URLResponse?, Error?) -> Void)) {
        
        requestData(url: url, method: method, queryParameters: queryParameters, body: body, validStatusCodes: validStatusCodes) { data, urlResponse, error in
            
            if let data = data {
                do {
                    completion(try JSONSerialization.jsonObject(with: data), nil, nil)
                } catch {
                    completion(nil, urlResponse, error)
                }
            } else {
                completion(nil, urlResponse, error)
            }
        }
    }
    
    public static func request<T: Decodable>(url: String,
                                             method: HTTPMethod = .get,
                                             queryParameters: Parameters? = nil,
                                             body: HTTPBody? = nil,
                                             validStatusCodes: [Int] = HTTPStatusCodes.successes,
                                             completion: @escaping DecodableRequestHandler<T>) {
        
        requestData(url: url, method: method, queryParameters: queryParameters, body: body, validStatusCodes: validStatusCodes) { (data, urlResponse, error) in
            
            if let data = data {
                do {
                    completion(try JSONDecoder().decode(T.self, from: data), urlResponse, nil)
                } catch {
                    completion(nil, urlResponse, error)
                }
            } else {
                completion(nil, urlResponse, error)
            }
        }
    }
}
