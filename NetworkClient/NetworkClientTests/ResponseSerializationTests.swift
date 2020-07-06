//
//  ResponseSerializationTests.swift
//  NetworkClientTests
//
//  Created by Jonathan Sahoo on 7/3/20.
//  Copyright © 2020 Jonathan Sahoo. All rights reserved.
//

import XCTest
@testable import NetworkClient

class ResponseSerializationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        NetworkClient.customResponseHandler = nil
        NetworkClient.baseURL = nil
    }

    // MARK: - Decodable + [Decodable]

    func testDeserializeDecodable() {
        let expectation = self.expectation(description: "")

        let url = "https://postman-echo.com/get"
        NetworkRequest(url: url).responseDecodable().done { (object: PostmanGetResponseCodable) in
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 10)
    }

    func testDeserializeArrayOfDecodable() {

        let expectation = self.expectation(description: "")

        let url = "https://jsonplaceholder.typicode.com/photos"
        NetworkRequest(url: url).responseDecodable().done { (photos: [PhotoCodable]) in
            XCTAssert(photos.isEmpty == false)
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 10)
    }

    // MARK: - Mappable

    func testDeserializeMappable() {
        let expectation = self.expectation(description: "")

        let url = "https://postman-echo.com/get"
        NetworkRequest(url: url).responseMappable().done { (object: PostmanGetResponseMappable) in
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 10)
    }

    func testDeserializeImmutableMappable() {
        let expectation = self.expectation(description: "")

        let url = "https://postman-echo.com/get"
        NetworkRequest(url: url).responseMappable().done { (object: PostmanGetResponseImmutableMappable) in
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 10)
    }

    // MARK: - [Mappable]

    func testDeserializeArrayOfMappable() {

        let expectation = self.expectation(description: "")

        let url = "https://jsonplaceholder.typicode.com/photos"
        NetworkRequest(url: url).responseMappableArray().done { (photos: [PhotoMappable]) in
            XCTAssert(photos.isEmpty == false)
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 10)
    }

    func testDeserializeArrayOfImmutableMappable() {

        let expectation = self.expectation(description: "")

        let url = "https://jsonplaceholder.typicode.com/photos"
        NetworkRequest(url: url).responseMappableArray().done { (photos: [PhotoImmutableMappable]) in
            XCTAssert(photos.isEmpty == false)
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 10)
    }
}
