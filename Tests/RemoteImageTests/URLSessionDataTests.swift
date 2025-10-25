// Created by Brad Bergeron on 9/10/23.

import Stubby
import XCTest

@testable import RemoteImage

// MARK: - URLSessionDataTests

final class URLSessionDataTests: XCTestCase {

  // MARK: Internal

  override func setUp() {
    urlSession = .stubbed(responseProvider: RemoteImageStubbedURL.self)
  }

  func test_dataWithCacheLoadInfo_skipCache_false() async throws {
    _ = try await urlSession.data(from: .cuteDoggoPicture)
    let (_, _, didLoadFromCache) = try await urlSession.data(from: .cuteDoggoPicture, skipCache: false)
    XCTAssertEqual(didLoadFromCache, true)
  }

  func test_dataWithCacheLoadInfo_skipCache_true() async throws {
    _ = try await urlSession.data(from: .cuteDoggoPicture)
    let (_, _, didLoadFromCache) = try await urlSession.data(from: .cuteDoggoPicture, skipCache: true)
    XCTAssertEqual(didLoadFromCache, false)
  }

  // MARK: Private

  private var urlSession: URLSession!

}
