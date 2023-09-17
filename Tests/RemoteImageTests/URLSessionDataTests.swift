// Created by Brad Bergeron on 9/10/23.

import Stubby
import XCTest

@testable import RemoteImage

// MARK: - URLSessionDataTests

final class URLSessionDataTests: XCTestCase {

  // MARK: Internal

  override func setUp() {
    urlSession = .stubbed(responder: RemoteImageStubbyResponder.self)
  }

  func test_dataWithCacheLoadInfo_skipCacheFalse_usesProtocolCachePolicy() async throws {
    try await urlSession.fetchImage(from: .cuteDoggo)
    let (_, _, didLoadFromCache) = try await urlSession.dataWithCacheLoadInfo(from: .cuteDoggo, skipCache: false)
    XCTAssertEqual(didLoadFromCache, true)
  }

  func test_dataWithCacheLoadInfo_skipCacheTrue_usesReloadIgnoringLocalCacheData() async throws {
    try await urlSession.fetchImage(from: .cuteDoggo)
    let (_, _, didLoadFromCache) = try await urlSession.dataWithCacheLoadInfo(from: .cuteDoggo, skipCache: true)
    XCTAssertEqual(didLoadFromCache, false)
  }

  // MARK: Private

  private var urlSession: URLSession!

}
