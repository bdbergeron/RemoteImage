// Created by Brad Bergeron on 9/17/23.

import Foundation
import Stubby
import XCTest

// MARK: - RemoteImageStubbyResponder

struct RemoteImageStubbyResponder: StubbyResponder {
  static func response(for request: URLRequest) throws -> Result<StubbyResponse, Error> {
    guard let url = request.url else {
      return .failure(URLError(.badURL))
    }
    switch url {
    case .cuteDoggo:
      return try .success(.cuteDoggo)
    case .invalidImage:
      return try .success(.invalidImage)
    default:
      XCTFail("No request mocked for url: \(url)")
      return .failure(URLError(.unsupportedURL))
    }
  }
}

extension StubbyResponse {
  fileprivate static var cuteDoggo: Self {
    get throws {
      try .init(
        url: .cuteDoggo,
        data: XCTUnwrap(.cuteDoggo))
    }
  }

  fileprivate static var invalidImage: Self {
    get throws {
      try .init(
        url: .invalidImage,
        data: XCTUnwrap("Hello, world!".data(using: .utf8)))
    }
  }
}
