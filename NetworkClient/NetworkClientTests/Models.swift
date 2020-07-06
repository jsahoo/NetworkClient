//
//  Models.swift
//  NetworkClientTests
//
//  Created by Jonathan Sahoo on 7/6/20.
//  Copyright © 2020 Jonathan Sahoo. All rights reserved.
//

import Foundation
import ObjectMapper

struct PostmanGetResponseCodable: Codable {
    var args: [String: String]
    var url: String
}

struct PostmanGetResponseMappable: Mappable {

    var args: [String: String]?
    var url: String?

    init?(map: Map) { }

    mutating func mapping(map: Map) {
        args <- map["args"]
        url <- map["url"]
    }
}

struct PostmanGetResponseImmutableMappable: ImmutableMappable {

    var args: [String: String]
    var url: String

    init(map: Map) throws {
        args = try map.value("args")
        url = try map.value("url")
    }
}

struct PhotoCodable: Codable {
    var title: String
    var thumbnailUrl: String
    var url: String
}

struct PhotoMappable: Mappable {

    var title: String?
    var thumbnailUrl: String?
    var url: String?

    init?(map: Map) { }

    mutating func mapping(map: Map) {
        title <- map["title"]
        thumbnailUrl <- map["thumbnailUrl"]
        url <- map["url"]
    }
}

struct PhotoImmutableMappable: ImmutableMappable {

    var title: String
    var thumbnailUrl: String
    var url: String

    init(map: Map) throws {
        title = try map.value("title")
        thumbnailUrl = try map.value("thumbnailUrl")
        url = try map.value("url")
    }
}
