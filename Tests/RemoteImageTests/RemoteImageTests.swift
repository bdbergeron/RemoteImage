// Created by Brad Bergeron on 9/1/23.

import Stubby
import SwiftUI
import ViewInspector
import XCTest

@testable import RemoteImage

// MARK: - RemoteImageTests

@MainActor
final class RemoteImageTests: XCTestCase {

  // MARK: Internal

  override func setUp() {
    urlSession = createURLSession()
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
    let expectedImage = try await urlSession.fetchImage(from: .cuteDoggo)
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
    let expectedImage = try await urlSession.fetchImage(from: .cuteDoggo)
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
    let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)
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
    let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)
    let configuration = URLSessionConfiguration.ephemeral
    configuration.urlCache = cache
    let urlSession = createURLSession(configuration: configuration)

    let expectedImage = try await urlSession.fetchImage(from: .cuteDoggo)
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
    let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)

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
    let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)
    let configuration = URLSessionConfiguration.ephemeral
    configuration.urlCache = cache
    let urlSession = createURLSession(configuration: configuration)

    let expectedImage = try await urlSession.fetchImage(from: .cuteDoggo)
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

  private var urlSession: URLSession!

  private func createURLSession(configuration: URLSessionConfiguration = .ephemeral) -> URLSession {
    .stubbed(
      responseProvider: RemoteImageStubbedURL.self,
      configuration: configuration)
  }

}
