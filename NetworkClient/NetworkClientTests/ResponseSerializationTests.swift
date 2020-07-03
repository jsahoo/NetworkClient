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

    func testDeserializeDecodable() {
        let expectation = self.expectation(description: "")

        let url = "https://postman-echo.com/get"
        NetworkRequest(url: url).responseDecodable().done { (object: PostmanGetResponse) in
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 10)
    }

    func testDeserializeArrayOfDecodable() {

        struct Photo: Codable {
            var title: String
            var thumbnailUrl: String
            var url: String
        }

        let expectation = self.expectation(description: "")

        let url = "https://jsonplaceholder.typicode.com/photos"
        NetworkRequest(url: url).responseDecodable().done { (photos: [Photo]) in
            XCTAssert(photos.isEmpty == false)
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 10)
    }
}
