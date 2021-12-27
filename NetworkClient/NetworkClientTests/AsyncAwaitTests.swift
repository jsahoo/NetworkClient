//
//  AsyncAwaitTests.swift
//  NetworkClientTests
//
//  Created by Jonathan Sahoo on 12/22/21.
//  Copyright © 2021 Jonathan Sahoo. All rights reserved.
//

import XCTest
@testable import NetworkClient

class AsyncAwaitTests: XCTestCase {

    override func setUpWithError() throws {
        NetworkClient.customResponseHandler = nil
        NetworkClient.baseURL = nil
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testResponseData() async throws {
        let response = try await NetworkRequest(url: "https://postman-echo.com/get").responseData()
        let data = response.data
        XCTAssertNotNil(data)
        XCTAssertNotNil(response.metadata)
    }

    func testResponseVoid() async throws {
        let metadata = try await NetworkRequest(url: "https://postman-echo.com/get").responseVoid().metadata
        XCTAssertNotNil(metadata)
    }

    func testResponseJSON() async throws {
        let response = try await NetworkRequest(url: "https://postman-echo.com/get").responseJSON()
        let json = response.json
        XCTAssertNotNil(json)
        XCTAssertNotNil(response.metadata)
    }

    func testResponseDecodable() async throws {
        let url = "https://postman-echo.com/get?foo1=bar1&foo2=bar2"
        let response = try await NetworkRequest(url: url).responseDecodable() as NetworkResponseDecodable<PostmanGetResponseCodable>
        let postmanGetResponseModel = response.decodableObject
        XCTAssertEqual(postmanGetResponseModel.args, ["foo1": "bar1", "foo2": "bar2"])
        XCTAssertNotNil(response.metadata)
    }

    func testFailureCase() async throws {
        
    }

    /// In this test we will only consider the request successful if the status code is 500. The test API will return 200, so the request should complete with an error.
    func testStatusCodeValidation() async throws {
        let url = "https://postman-echo.com/get"
        let validStatusCodes = [500]

        do {
            let _ = try await NetworkRequest(url: url, validStatusCodes: validStatusCodes).responseData()
            XCTFail("Request should have failed and execution should have jumped to catch block")
        } catch {
            guard let error = error as? NetworkResponseError else {
                XCTFail()
                return
            }
            XCTAssertNotEqual(error.responseMetadata?.response?.statusCode, 500)
            switch error.error as? NetworkError {
            case .some(.invalidStatusCode):
                break
            default:
                XCTFail("Error should have been .invalidStatusCode")
            }
        }
    }
}
