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

    override func setUp() {
        super.setUp()
        NetworkClient.customResponseHandler = nil
        NetworkClient.baseURL = nil
    }

    func testBasicGETRequest() {
        let expectation = self.expectation(description: "")

        NetworkRequest(url: "https://postman-echo.com/get").responseData().done { data in
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 10)
    }

    func testGETRequestWithQueryParameters() {
        let expectation = self.expectation(description: "")

        let url = "https://postman-echo.com/get"
        let queryParameters: Parameters = ["foo1": "bar1", "foo2": "bar2"]
        NetworkRequest(url: url, queryParameters: queryParameters).responseDecodable().done { (responseObject: PostmanGetResponse) in
            XCTAssertEqual(responseObject.args, queryParameters as? [String: String])
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 10)
    }

    func testGetRequestWithQueryParametersInURL() {
        let expectation = self.expectation(description: "")

        let url = "https://postman-echo.com/get?foo1=bar1&foo2=bar2"
        NetworkRequest(url: url).responseDecodable().done { (responseObject: PostmanGetResponse) in
            XCTAssertEqual(responseObject.args, ["foo1": "bar1", "foo2": "bar2"])
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 10)
    }

    /// In this test we will only consider the request successful if the status code is 500. The test API will return 200, so the request should complete with an error.
    func testStatusCodeValidation() {
        let expectation = self.expectation(description: "Request should fail due to invalid status code.")

        let url = "https://postman-echo.com/get"
        NetworkRequest(url: url, validStatusCodes: [500]).responseDataWithMetadata().done { _ in
            XCTFail("Request should not have succeeded")
        }.catch { error in
            guard let error = error as? PromiseNetworkError else {
                XCTFail()
                return
            }
            XCTAssertNotEqual(error.responseMetadata?.response?.statusCode, 500)
            switch error.error as? NetworkError {
            case .some(.invalidStatusCode):
                expectation.fulfill()
            default:
                XCTFail("Error should have been .invalidStatusCode")
            }
        }

        waitForExpectations(timeout: 10)
    }

    func testCustomResponseHandler() {
        let testError = NSError(domain: "Test", code: 0, userInfo: nil)

        NetworkClient.customResponseHandler = { networkRequest, metadata, data, urlResponse, error -> (Swift.Result<Data, Error>, ResponseMetadata) in
            // For testing purposes, we'll make this custom response handler error out with a custom error
            return (.failure(testError), ResponseMetadata(response: urlResponse as? HTTPURLResponse, data: data))
        }

        let expectation = self.expectation(description: "")

        NetworkRequest(url: "https://postman-echo.com/get").responseData().done { data in
            XCTFail("Request should not have succeeded")
        }.catch { error in
            XCTAssertEqual(error as NSError, testError)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    /// Use a custom response handler to recreate the default response handling logic while also adding additional custom logic
    func testCustomResponseHandler2() {
        let testString = "Testing123"

        NetworkClient.customResponseHandler = { networkRequest, metadata, data, urlResponse, error -> (Swift.Result<Data, Error>, ResponseMetadata) in

            // Recreate the default response handling logic

            var metadata = metadata
            metadata.data = data
            metadata.response = urlResponse as? HTTPURLResponse

            if let error = error {
                return (.failure(error), metadata)
            }

            guard let urlResponse = urlResponse as? HTTPURLResponse else {
                return (.failure(NetworkError.noResponse), metadata)
            }

            guard networkRequest.validStatusCodes.contains(urlResponse.statusCode) else {
                return (.failure(NetworkError.invalidStatusCode(urlResponse.statusCode)), metadata)
            }

            guard let _ = data else {
                return (.failure(NetworkError.noData), metadata)
            }

            // Additional custom logic

            let testStringAsData = testString.data(using: .utf8)!
            return (.success(testStringAsData), metadata)
        }

        let expectation = self.expectation(description: "")

        NetworkRequest(url: "https://postman-echo.com/get").responseData().done { data in
            // Normally this request would return a PostmanGetResponse, but because we've created a custom response handler to return our custom data, that's what we should get
            XCTAssertEqual(testString, String(data: data, encoding: .utf8)!)
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 10)
    }

    func testDefaultBaseURL() {
        NetworkClient.baseURL = {
            return "https://postman-echo.com"
        }

        let expectation = self.expectation(description: "")

        NetworkRequest(path: "/get").responseDecodable().done { (object: PostmanGetResponse) in
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 10)
    }
}

struct PostmanGetResponse: Codable {
    var args: [String: String]
    var url: String
}
