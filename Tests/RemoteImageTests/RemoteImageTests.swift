// Created by Brad Bergeron on 9/1/23.

import SwiftUI
import ViewInspector
import XCTest

@testable import RemoteImage

@MainActor
final class RemoteImageTests: XCTestCase {

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

  func test_initWithURLSession_createsViewModelWithDefaults() throws {
    var view = RemoteImage(url: .cuteDoggo)

    let expectation = view.on(\.didAppear) { inspectable in
      let viewModel = try inspectable.actualView().model
      viewModel.validateDefaultValues(url: .cuteDoggo)
    }

    ViewHosting.host(view: view)
    wait(for: [expectation])
  }

  func test_initWithURLSession_usesEmptyPlaceholderImage() throws {
    var view = RemoteImage(url: .cuteDoggo, urlSession: urlSession)

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let image = try inspectable.image(0).actualImage()
      let expectedImage = Image(uiImage: .init())
      XCTAssertEqual(image, expectedImage)
    }

    ViewHosting.host(view: view)
    wait(for: [expectation])
  }

  func test_initWithURLSession_usesLoadedImage() async throws {
    try MockURLProtocol.configureRequestHandler(with: .cuteDoggo)
    let expectedImage = try await urlSession.fetchAndCacheImage(from: .cuteDoggo)
    var view = RemoteImage(url: .cuteDoggo, urlSession: urlSession)

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let image = try inspectable.image(0).actualImage()
      XCTAssertEqual(image.uiImageRepresentation()?.pngData(), expectedImage.uiImageRepresentation()?.pngData())
    }

    ViewHosting.host(view: view)
    await fulfillment(of: [expectation])
  }

  func test_initWithURLSession_contentAndPlaceholder_showsPlaceholder() throws {
    var view = RemoteImage(url: .cuteDoggo, urlSession: urlSession) { image in
      image
    } placeholder: {
      ProgressView()
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      XCTAssertNotNil(try inspectable.progressView(0))
    }

    ViewHosting.host(view: view)
    wait(for: [expectation])
  }

  func test_initWithURLSession_contentAndPlaceholder_showsLoadedImage() async throws {
    try MockURLProtocol.configureRequestHandler(with: .cuteDoggo)
    let expectedImage = try await urlSession.fetchAndCacheImage(from: .cuteDoggo)
    var view = RemoteImage(url: .cuteDoggo, urlSession: urlSession) { image in
      image
    } placeholder: {
      ProgressView()
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let image = try inspectable.image(0).actualImage()
      XCTAssertEqual(image.uiImageRepresentation()?.pngData(), expectedImage.uiImageRepresentation()?.pngData())
    }

    ViewHosting.host(view: view)
    await fulfillment(of: [expectation])
  }

  func test_initWithCache_usesEmptyPlaceholderImage() throws {
    var view = RemoteImage(url: .cuteDoggo, cache: cache)

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let image = try inspectable.image(0).actualImage()
      let expectedImage = Image(uiImage: .init())
      XCTAssertEqual(image, expectedImage)
    }

    ViewHosting.host(view: view)
    wait(for: [expectation])
  }

  func test_initWithCache_usesLoadedImage() async throws {
    try MockURLProtocol.configureRequestHandler(with: .cuteDoggo)
    let expectedImage = try await urlSession.fetchAndCacheImage(from: .cuteDoggo)
    var view = RemoteImage(url: .cuteDoggo, cache: cache)

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let image = try inspectable.image(0).actualImage()
      XCTAssertEqual(image.uiImageRepresentation()?.pngData(), expectedImage.uiImageRepresentation()?.pngData())
    }

    ViewHosting.host(view: view)
    await fulfillment(of: [expectation])
  }

  func test_initWithCache_contentAndPlaceholder_showsPlaceholder() throws {
    var view = RemoteImage(url: .cuteDoggo, cache: cache) { image in
      image
    } placeholder: {
      ProgressView()
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      XCTAssertNotNil(try inspectable.progressView(0))
    }

    ViewHosting.host(view: view)
    wait(for: [expectation])
  }

  func test_initWithCache_contentAndPlaceholder_showsLoadedImage() async throws {
    try MockURLProtocol.configureRequestHandler(with: .cuteDoggo)
    let expectedImage = try await urlSession.fetchAndCacheImage(from: .cuteDoggo)
    var view = RemoteImage(url: .cuteDoggo, cache: cache) { image in
      image
    } placeholder: {
      ProgressView()
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let image = try inspectable.image(0).actualImage()
      XCTAssertEqual(image.uiImageRepresentation()?.pngData(), expectedImage.uiImageRepresentation()?.pngData())
    }

    ViewHosting.host(view: view)
    await fulfillment(of: [expectation])
  }

  // MARK: Private

  private var cache: URLCache!
  private var urlSession: URLSession!

}
