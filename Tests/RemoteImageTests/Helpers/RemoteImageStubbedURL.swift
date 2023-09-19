// Created by Brad Bergeron on 9/17/23.

import Foundation
import Stubby
import XCTest

// MARK: - RemoteImageStubbedURL

enum RemoteImageStubbedURL: CaseIterable {
  /// A picture of a cute doggo. 🐶
  case cuteDoggoPicture
  /// A non-image URL.
  case invalidImage
}

// MARK: RawRepresentable

extension RemoteImageStubbedURL: RawRepresentable {
  init?(rawValue: URL) {
    guard let stubbedURL = Self.allCases.first(where: { $0.rawValue == rawValue }) else { return nil }
    self = stubbedURL
  }

  var rawValue: URL {
    switch self {
    case .cuteDoggoPicture:
      return .cuteDoggoPicture
    case .invalidImage:
      return .invalidImage
    }
  }
}

// MARK: StubbyResponseProvider

extension RemoteImageStubbedURL: StubbyResponseProvider {

  // MARK: Internal

  static func respondsTo(request: URLRequest) -> Bool {
    request.url.map { allCases.map(\.rawValue).contains($0) } ?? false
  }

  static func response(for request: URLRequest) throws -> Result<StubbyResponse, Error> {
    guard let url = request.url else {
      return .failure(URLError(.badURL))
    }
    guard let stubbedURL = Self(rawValue: url) else {
      XCTFail("No request mocked for url: \(url)")
      return .failure(URLError(.unsupportedURL))
    }
    return try stubbedURL.response
  }

  // MARK: Private

  private var response: Result<StubbyResponse, Error> {
    get throws {
      switch self {
      case .cuteDoggoPicture:
        return try .success(
          .init(
            data: try XCTUnwrap(.cuteDoggo),
            for: rawValue,
            cacheStoragePolicy: .allowedInMemoryOnly))

      case .invalidImage:
        return try .success(
          .init(
            data: try XCTUnwrap("Hello, world!".data(using: .utf8)),
            for: rawValue))
      }
    }
  }

}
