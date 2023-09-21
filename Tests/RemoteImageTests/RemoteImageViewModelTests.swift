// Created by Brad Bergeron on 8/31/23.

import OSLog
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
    let model = RemoteImageViewModel(url: .cuteDoggoPicture)
    model.validateDefaultValues(url: .cuteDoggoPicture)
  }

  func test_cachedImage_returnsNilIfNoURL() {
    let model = RemoteImageViewModel(url: nil, urlSession: urlSession)
    XCTAssertNil(model.cachedImage)
  }

  func test_cachedImage_returnsNilIfSkipCache() {
    let model = RemoteImageViewModel(
      url: nil, 
      urlSession: urlSession,
      configuration: .init(
        skipCache: true))
    XCTAssertNil(model.cachedImage)
  }

  func test_cachedImage_returnsNilIfNoCacheHit() {
    let model = RemoteImageViewModel(url: .cuteDoggoPicture, urlSession: urlSession)
    XCTAssertNil(model.cachedImage)
  }

  func test_cachedImage_returnsImageIfCacheHit() async throws {
    try await urlSession.fetchImage(from: .cuteDoggoPicture)
    let model = RemoteImageViewModel(url: .cuteDoggoPicture, urlSession: urlSession)
    XCTAssertNotNil(model.cachedImage)
  }

  func test_createImage_throwsOnInvalidData() {
    let model = RemoteImageViewModel(url: .cuteDoggoPicture, urlSession: urlSession)
    XCTAssertThrowsError(try model.createImage(with: .init())) { error in
      guard case .invalidImageData = error as? RemoteImageViewModel.Error else {
        XCTFail("Error should be `.invalidImageData`.")
        return
      }
    }
  }

  func test_loadImage_skipsLoadIfPhaseIsAlreadyLoaded() async throws {
    try await urlSession.fetchImage(from: .cuteDoggoPicture)
    let model = RemoteImageViewModel(url: .cuteDoggoPicture, urlSession: urlSession)
    model.onAppear()
    guard case .loaded = model.phase else {
      XCTFail("Initial phase should be `.loaded`.")
      return
    }
    
    model.onAppear()
    XCTAssertNil(model.loadingTask)

    guard case .loaded = model.phase else {
      XCTFail("Phase should still be `.loaded`.")
      return
    }
  }

  func test_loadImage_skipsLoadIfNoURL() async throws {
    let model = RemoteImageViewModel(url: nil)
    guard case .placeholder = model.phase else {
      XCTFail("Initial phase should be `.placeholder`.")
      return
    }
    
    model.onAppear()
    let task = try XCTUnwrap(model.loadingTask)
    try await task.value

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

    model.onAppear()
    let task = try XCTUnwrap(model.loadingTask)
    try await task.value

    guard case .failure(let error) = model.phase else {
      XCTFail("Phase should be `.failure`.")
      return
    }
    guard case .invalidImageData = error as? RemoteImageViewModel.Error else {
      XCTFail("Error should be `.invalidImageData`.")
      return
    }
  }

  func test_loadImage_succeedsWithLoadedImage_animated() async throws {
    let model = RemoteImageViewModel(url: .cuteDoggoPicture, urlSession: urlSession)
    guard case .placeholder = model.phase else {
      XCTFail("Initial phase should be `.placeholder`.")
      return
    }
    
    model.onAppear()
    let task = try XCTUnwrap(model.loadingTask)
    try await task.value

    guard case .loaded = model.phase else {
      XCTFail("Phase should be `.loaded`.")
      return
    }
  }

  func test_loadImage_succeedsWithCachedImage_notAnimated() async throws {
    let model = RemoteImageViewModel(url: .cuteDoggoPicture, urlSession: urlSession)
    guard case .placeholder = model.phase else {
      XCTFail("Initial phase should be `.placeholder`.")
      return
    }

    try await urlSession.fetchImage(from: .cuteDoggoPicture)
    
    model.onAppear()
    XCTAssertNil(model.loadingTask)

    guard case .loaded = model.phase else {
      XCTFail("Phase should be `.loaded`.")
      return
    }
  }

  func test_loadImage_stopsLoadingIfCancelled() async throws {
    let model = RemoteImageViewModel(url: .cuteDoggoPicture, urlSession: urlSession)
    guard case .placeholder = model.phase else {
      XCTFail("Initial phase should be `.placeholder`.")
      return
    }

    model.onAppear()
    let task = try XCTUnwrap(model.loadingTask)
    XCTAssertFalse(task.isCancelled)

    model.onDisappear()
    XCTAssertTrue(task.isCancelled)
    XCTAssertNil(model.loadingTask)
    try await task.value

    guard case .placeholder = model.phase else {
      XCTFail("Phase should be `.placeholder`.")
      return
    }
  }

  func test_loadImage_loadsIfPreviouslyCancelled() async throws {
    let model = RemoteImageViewModel(url: .cuteDoggoPicture, urlSession: urlSession)
    guard case .placeholder = model.phase else {
      XCTFail("Initial phase should be `.placeholder`.")
      return
    }

    model.onAppear()
    var task = try XCTUnwrap(model.loadingTask)
    XCTAssertFalse(task.isCancelled)

    model.onDisappear()
    XCTAssertTrue(task.isCancelled)
    XCTAssertNil(model.loadingTask)
    try await task.value

    guard case .placeholder = model.phase else {
      XCTFail("Phase should be `.placeholder`.")
      return
    }

    model.onAppear()
    task = try XCTUnwrap(model.loadingTask)
    try await task.value

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
