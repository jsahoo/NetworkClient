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

    func testResponseDataWithMetadata() async throws {
        let (_, metadata) = try await NetworkRequest(url: "https://postman-echo.com/get").responseDataWithMetadata()
        XCTAssertNotNil(metadata)
    }

    func testResponseData() async throws {
        _ = try await NetworkRequest(url: "https://postman-echo.com/get").responseData()
    }

    func testResponseVoidWithMetadata() async throws {
        let (_, metadata) = try await NetworkRequest(url: "https://postman-echo.com/get").responseVoidWithMetadata()
        XCTAssertNotNil(metadata)
    }

    func testResponseVoid() async throws {
        try await NetworkRequest(url: "https://postman-echo.com/get").responseVoid()
    }

    func testResponseJSONWithMetadata() async throws {
        let (json, metadata) = try await NetworkRequest(url: "https://postman-echo.com/get").responseJSONWithMetadata()
        XCTAssertNotNil(json)
        XCTAssertNotNil(metadata)
    }

    func testResponseJSON() async throws {
        let json = try await NetworkRequest(url: "https://postman-echo.com/get").responseJSON()
        XCTAssertNotNil(json)
    }

    func testResponseDecodableWithMetadata() async throws {
        let url = "https://postman-echo.com/get?foo1=bar1&foo2=bar2"
        let (codableResponse, metadata) = try await NetworkRequest(url: url).responseDecodableWithMetadata() as (PostmanGetResponseCodable, ResponseMetadata?)
        XCTAssertEqual(codableResponse.args, ["foo1": "bar1", "foo2": "bar2"])
        XCTAssertNotNil(metadata)
    }

    func testResponseDecodable() async throws {
        let url = "https://postman-echo.com/get?foo1=bar1&foo2=bar2"
        let responseArgs = try await (NetworkRequest(url: url).responseDecodable() as PostmanGetResponseCodable).args
        XCTAssertEqual(responseArgs, ["foo1": "bar1", "foo2": "bar2"])
    }

    // MARK: V2 Functions

    func testResponseDataV2() async throws {
        let response = try await NetworkRequest(url: "https://postman-echo.com/get").responseDataV2()
        let data = response.object
        XCTAssertNotNil(data)
        XCTAssertNotNil(response.metadata)
    }

    func testResponseVoidV2() async throws {
        let response = try await NetworkRequest(url: "https://postman-echo.com/get").responseVoidV2()
        let void: Void = response.object
        XCTAssertNotNil(void)
        XCTAssertNotNil(response.metadata)
    }

    func testResponseJSONV2() async throws {
        let response = try await NetworkRequest(url: "https://postman-echo.com/get").responseJSONV2()
        let json = response.object
        XCTAssertNotNil(json)
        XCTAssertNotNil(response.metadata)
    }

    func testResponseDecodableV2() async throws {
        let url = "https://postman-echo.com/get?foo1=bar1&foo2=bar2"
        let response = try await NetworkRequest(url: url).responseDecodableV2() as NetworkResponse<PostmanGetResponseCodable>
        let postmanGetResponseModel = response.object
        XCTAssertEqual(postmanGetResponseModel.args, ["foo1": "bar1", "foo2": "bar2"])
        XCTAssertNotNil(response.metadata)
    }

    // MARK: V3 Functions

    func testResponseDataV3() async throws {
        let response = try await NetworkRequest(url: "https://postman-echo.com/get").responseDataV3()
        let data = response.data
        XCTAssertNotNil(data)
        XCTAssertNotNil(response.metadata)
    }

    func testResponseVoidV3() async throws {
        let metadata = try await NetworkRequest(url: "https://postman-echo.com/get").responseVoidV3().metadata
        XCTAssertNotNil(metadata)
    }

    func testResponseJSONV3() async throws {
        let response = try await NetworkRequest(url: "https://postman-echo.com/get").responseJSONV3()
        let json = response.json
        XCTAssertNotNil(json)
        XCTAssertNotNil(response.metadata)
    }

    func testResponseDecodableV3() async throws {
        let url = "https://postman-echo.com/get?foo1=bar1&foo2=bar2"
        let response = try await NetworkRequest(url: url).responseDecodableV3() as NetworkResponseDecodable<PostmanGetResponseCodable>
        let postmanGetResponseModel = response.decodableObject
        XCTAssertEqual(postmanGetResponseModel.args, ["foo1": "bar1", "foo2": "bar2"])
        XCTAssertNotNil(response.metadata)
    }
}
