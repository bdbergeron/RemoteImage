// Created by Brad Bergeron on 8/31/23.

import Stubby
import SwiftUI
import XCTest

@testable import RemoteImage

// MARK: - RemoteImageViewModelTests

@MainActor
final class RemoteImageViewModelTests: XCTestCase {

  // MARK: Internal

  override func setUp() {
    urlSession = .stubbed(responseProvider: RemoteImageStubbedURL.self)
  }

  func test_initWithDefaultValues() {
    let model = RemoteImageViewModel(url: .cuteDoggo)
    model.validateDefaultValues(url: .cuteDoggo)
  }

  func test_cachedImage_returnsNilIfNoURL() {
    let model = RemoteImageViewModel(url: nil, urlSession: urlSession)
    XCTAssertNil(model.cachedImage)
  }

  func test_cachedImage_returnsNilIfSkipCache() {
    let model = RemoteImageViewModel(url: nil, urlSession: urlSession, skipCache: true)
    XCTAssertNil(model.cachedImage)
  }

  func test_cachedImage_returnsNilIfNoCacheHit() {
    let model = RemoteImageViewModel(url: .cuteDoggo, urlSession: urlSession)
    XCTAssertNil(model.cachedImage)
  }

  func test_cachedImage_returnsImageIfCacheHit() async throws {
    try await urlSession.fetchImage(from: .cuteDoggo)
    let model = RemoteImageViewModel(url: .cuteDoggo, urlSession: urlSession)
    XCTAssertNotNil(model.cachedImage)
  }

  func test_createImage_throwsOnInvalidData() {
    let model = RemoteImageViewModel(url: .cuteDoggo, urlSession: urlSession)
    XCTAssertThrowsError(try model.createImage(with: .init())) { error in
      guard case .invalidImageData = error as? RemoteImageViewModel.Error else {
        XCTFail("Error should be `.invalidImageData`.")
        return
      }
    }
  }

  func test_loadImage_skipsLoadIfPhaseIsAlreadyLoaded() async throws {
    try await urlSession.fetchImage(from: .cuteDoggo)
    let model = RemoteImageViewModel(url: .cuteDoggo, urlSession: urlSession)
    model.onAppear()
    guard case .loaded = model.phase else {
      XCTFail("Initial phase should be `.loaded`.")
      return
    }
    await model.loadImageIfNeeded()
    guard case .loaded = model.phase else {
      XCTFail("Phase should still be `.loaded`.")
      return
    }
  }

  func test_loadImage_skipsLoadIfNoURL() async {
    let model = RemoteImageViewModel(url: nil)
    guard case .placeholder = model.phase else {
      XCTFail("Initial phase should be `.placeholder`.")
      return
    }
    await model.loadImageIfNeeded()
    guard case .placeholder = model.phase else {
      XCTFail("Phase should still be `.placeholder`.")
      return
    }
  }

  func test_loadImage_failsIfInvalidImageURL() async throws {
    let model = RemoteImageViewModel(url: .invalidImage, urlSession: urlSession)
    guard case .placeholder = model.phase else {
      XCTFail("Initial phase should be `.placeholder`.")
      return
    }
    await model.loadImageIfNeeded()
    guard case .failure(let error) = model.phase else {
      XCTFail("Phase should be `.failure`.")
      return
    }
    guard case .invalidImageData = error as? RemoteImageViewModel.Error else {
      XCTFail("Error should be `.invalidImageData`.")
      return
    }
  }

  func test_loadImage_succeedsAnimated() async throws {
    let model = RemoteImageViewModel(url: .cuteDoggo, urlSession: urlSession)
    guard case .placeholder = model.phase else {
      XCTFail("Initial phase should be `.placeholder`.")
      return
    }
    await model.loadImageIfNeeded()
    guard case .loaded = model.phase else {
      XCTFail("Phase should be `.loaded`.")
      return
    }
  }

  func test_loadImage_succeedsNotAnimated() async throws {
    let model = RemoteImageViewModel(url: .cuteDoggo, urlSession: urlSession)
    guard case .placeholder = model.phase else {
      XCTFail("Initial phase should be `.placeholder`.")
      return
    }
    try await urlSession.fetchImage(from: .cuteDoggo)
    await model.loadImageIfNeeded()
    guard case .loaded = model.phase else {
      XCTFail("Phase should be `.loaded`.")
      return
    }
  }

  // MARK: Private

  private var urlSession: URLSession!

}

extension RemoteImageViewModel {
  func validateDefaultValues(url: URL) {
    XCTAssertEqual(self.url, url)
    XCTAssertEqual(urlSession, .shared)
    XCTAssertEqual(skipCache, false)
    XCTAssertEqual(scale, 1.0)
    XCTAssertEqual(transaction, .init())
    XCTAssertEqual(disableTransactionWithCachedResponse, true)
    XCTAssertEqual(cache, .shared)
  }
}

// MARK: - Transaction + Equatable

extension Transaction: Equatable {
  public static func ==(lhs: Transaction, rhs: Transaction) -> Bool {
    lhs.disablesAnimations == rhs.disablesAnimations
      && lhs.isContinuous == rhs.isContinuous
      && lhs.animation == rhs.animation
  }
}
