//
//  NetworkClientTests.swift
//  NetworkClientTests
//
//  Created by Jonathan Sahoo on 1/9/20.
//  Copyright © 2020 Jonathan Sahoo. All rights reserved.
//

import XCTest
@testable import NetworkClient

class NetworkClientTests: XCTestCase {

    func testGetRequestSingleObjectResponse() {
        let expectation = self.expectation(description: "Request should succeed; response should contain a single item.")
        
        let url = "https://postman-echo.com/get"
        NetworkClient.request(url: url) { (responseObject: PostmanGetResponse?, urlResponse, error) in
            XCTAssertNotNil(responseObject)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func testGetRequestArrayResponse() {
        
        struct Photo: Codable {
            var title: String
            var thumbnailUrl: String
            var url: String
        }
        
        let expectation = self.expectation(description: "Request should succeed; response should contain an array of items.")
        
        let url = "https://jsonplaceholder.typicode.com/photos"
        NetworkClient.request(url: url) { (photos: [Photo]?, urlResponse, error) in
            XCTAssertNotNil(photos)
            XCTAssert(photos?.isEmpty == false)
            XCTAssertNotNil(urlResponse)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func testGetRequestWithQueryParameters() {
        let expectation = self.expectation(description: "Request should succeed; server should recognize query parameters passed in.")
        
        let url = "https://postman-echo.com/get"
        let queryParameters: Parameters = ["foo1": "bar1", "foo2": "bar2"]
        NetworkClient.request(url: url, queryParameters: queryParameters) { (responseObject: PostmanGetResponse?, urlResponse, error) in
            XCTAssertNotNil(responseObject)
            XCTAssertEqual(responseObject?.args, queryParameters as? [String: String])
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func testGetRequestWithQueryParametersInURL() {
        let expectation = self.expectation(description: "Request should succeed; server should recognize query parameters embedded in the URL.")
        
        let url = "https://postman-echo.com/get?foo1=bar1&foo2=bar2"
        NetworkClient.request(url: url) { (responseObject: PostmanGetResponse?, urlResponse, error) in
            XCTAssertNotNil(responseObject)
            XCTAssertEqual(responseObject?.args, ["foo1": "bar1", "foo2": "bar2"])
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    /// In this test we will only consider the request successful if the status code is 500. The test API will return 200, so the request should complete with an error.
    func testStatusCodeValidation() {
        let expectation = self.expectation(description: "Request should fail due to invalid status code.")
        
        let url = "https://postman-echo.com/get"
        NetworkClient.request(url: url, validStatusCodes: [500]) { (responseObject: PostmanGetResponse?, urlResponse, error) in
            XCTAssertNil(responseObject)
            XCTAssertNotNil(error)
            XCTAssert((error as? NetworkError) == .invalidStatusCode)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
}

struct PostmanGetResponse: Codable {
    var args: [String: String]
    var url: String
}
