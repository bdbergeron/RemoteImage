// Created by Brad Bergeron on 9/10/23.

import XCTest

@testable import RemoteImage

final class URLSessionDataTests: XCTestCase {

  // MARK: Internal

  override func setUp() {
    cache = .testCache
    let configuration = URLSessionConfiguration.default
    configuration.urlCache = cache
    configuration.protocolClasses = [MockURLProtocol.self]
    urlSession = URLSession(configuration: configuration)
  }

  override func tearDown() async throws {
    MockURLProtocol.resetRequestHandler()
    try await cache.clear()
  }

  func test_dataWithCacheLoadInfo_skipCacheFalse_usesProtocolCachePolicy() async throws {
    try MockURLProtocol.configureRequestHandler(with: .cuteDoggo)
    try await urlSession.fetchAndCacheImage(from: .cuteDoggo)
    let (_, _, didLoadFromCache) = try await urlSession.dataWithCacheLoadInfo(from: .cuteDoggo, skipCache: false)
    XCTAssertEqual(didLoadFromCache, true)
  }

  func test_dataWithCacheLoadInfo_skipCacheTrue_usesReloadIgnoringLocalCacheData() async throws {
    try MockURLProtocol.configureRequestHandler(with: .cuteDoggo)
    try await urlSession.fetchAndCacheImage(from: .cuteDoggo)
    let (_, _, didLoadFromCache) = try await urlSession.dataWithCacheLoadInfo(from: .cuteDoggo, skipCache: true)
    XCTAssertEqual(didLoadFromCache, false)
  }

  // MARK: Private

  private var cache: URLCache!
  private var urlSession: URLSession!

}
