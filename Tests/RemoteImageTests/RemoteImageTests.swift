// Created by Brad Bergeron on 9/1/23.

import Foundation
import Stubby
import SwiftUI
import ViewInspector
import XCTest

@testable import RemoteImage

// MARK: - RemoteImageTests

@MainActor
final class RemoteImageTests: XCTestCase {

  // MARK: Internal

  override func setUp() async throws {
    urlSession = createURLSession()
  }

  func test_initWithURLSession_createsViewModelWithDefaults() {
    var view = RemoteImage(url: .cuteDoggoPicture)

    let expectation = view.on(\.didAppear) { inspectable in
      let viewModel = try inspectable.actualView().model
      viewModel.validateDefaultValues(url: .cuteDoggoPicture)
    }

    ViewHosting.host(view: view)
    wait(for: [expectation])
  }

  func test_initWithURLSession_usesEmptyPlaceholderImage() {
    var view = RemoteImage(url: .cuteDoggoPicture, urlSession: urlSession)

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let image = try inspectable.image().actualImage()
      let expectedImage = Image(nativeImage: .init())
      XCTAssertEqual(image.dataRepresentation(), expectedImage.dataRepresentation())
    }

    ViewHosting.host(view: view)
    wait(for: [expectation])
  }

  func test_initWithURLSession_usesLoadedImage() async throws {
    let expectedImage = try await urlSession.fetchImage(from: .cuteDoggoPicture)
    var view = RemoteImage(url: .cuteDoggoPicture, urlSession: urlSession)

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let image = try inspectable.image().actualImage()
      XCTAssertEqual(image.dataRepresentation(), expectedImage.dataRepresentation())
    }

    ViewHosting.host(view: view)
    await fulfillment(of: [expectation])
  }

  func test_initWithURLSession_callsContentClosure() async throws {
    let expectedImage = try await urlSession.fetchImage(from: .cuteDoggoPicture)
    var view = RemoteImage(url: .cuteDoggoPicture, urlSession: urlSession) { image in
      image.resizable().scaledToFit()
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let imageView = try inspectable.image()
      XCTAssertTrue(try imageView.isScaledToFit())
      let image = try imageView.actualImage()
      XCTAssertEqual(image.dataRepresentation(), expectedImage.dataRepresentation())
    }

    ViewHosting.host(view: view)
    await fulfillment(of: [expectation])
  }

  func test_initWithURLSession_contentAndPlaceholder_showsPlaceholder() {
    var view = RemoteImage(url: .cuteDoggoPicture, urlSession: urlSession) { image in
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
    let expectedImage = try await urlSession.fetchImage(from: .cuteDoggoPicture)
    var view = RemoteImage(url: .cuteDoggoPicture, urlSession: urlSession) { image in
      image
    } placeholder: {
      ProgressView()
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let image = try inspectable.image().actualImage()
      XCTAssertEqual(image.dataRepresentation(), expectedImage.dataRepresentation())
    }

    ViewHosting.host(view: view)
    await fulfillment(of: [expectation])
  }

  func test_initWithURLSession_contentPlaceholderFailure_showsPlaceholder() {
    var view = RemoteImage(url: .cuteDoggoPicture, urlSession: urlSession) { image in
      image
    } placeholder: {
      ProgressView()
    } failure: { _ in
      Text("Failed to load image.")
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      XCTAssertNotNil(try inspectable.progressView())
    }

    ViewHosting.host(view: view)
    wait(for: [expectation])
  }

  func test_initWithURLSession_contentPlaceholderFailure_showsFailure() async throws {
    _ = try await urlSession.data(from: .invalidImage)
    var view = RemoteImage(url: .invalidImage, urlSession: urlSession) { image in
      image
    } placeholder: {
      ProgressView()
    } failure: { _ in
      Text("Failed to load image.")
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let viewModel = try inspectable.actualView().model
      viewModel.phase = .failure(URLError(.unsupportedURL))
      let text = try inspectable.text()
      XCTAssertEqual(try text.string(), "Failed to load image.")
    }

    ViewHosting.host(view: view)
    await fulfillment(of: [expectation])
  }

  func test_initWithURLSession_contentPlaceholderFailure_showsLoadedImage() async throws {
    let expectedImage = try await urlSession.fetchImage(from: .cuteDoggoPicture)
    var view = RemoteImage(url: .cuteDoggoPicture, urlSession: urlSession) { image in
      image
    } placeholder: {
      ProgressView()
    } failure: { _ in
      Text("Failed to load image.")
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let image = try inspectable.image().actualImage()
      XCTAssertEqual(image.dataRepresentation(), expectedImage.dataRepresentation())
    }

    ViewHosting.host(view: view)
    await fulfillment(of: [expectation])
  }

  func test_initWithCache_usesEmptyPlaceholderImage() {
    let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)
    var view = RemoteImage(url: .cuteDoggoPicture, cache: cache)

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let image = try inspectable.image().actualImage()
      let expectedImage = Image(nativeImage: .init())
      XCTAssertEqual(image.dataRepresentation(), expectedImage.dataRepresentation())
    }

    ViewHosting.host(view: view)
    wait(for: [expectation])
  }

  func test_initWithCache_usesLoadedImage() async throws {
    let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)
    let configuration = URLSessionConfiguration.ephemeral
    configuration.urlCache = cache
    let urlSession = createURLSession(configuration: configuration)

    let expectedImage = try await urlSession.fetchImage(from: .cuteDoggoPicture)
    var view = RemoteImage(url: .cuteDoggoPicture, cache: cache)

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let image = try inspectable.image().actualImage()
      XCTAssertEqual(image.dataRepresentation(), expectedImage.dataRepresentation())
    }

    ViewHosting.host(view: view)
    await fulfillment(of: [expectation])
  }

  func test_initWithCache_callsContentClosure() async throws {
    let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)
    let configuration = URLSessionConfiguration.ephemeral
    configuration.urlCache = cache
    let urlSession = createURLSession(configuration: configuration)

    let expectedImage = try await urlSession.fetchImage(from: .cuteDoggoPicture)
    var view = RemoteImage(url: .cuteDoggoPicture, cache: cache) { image in
      image.resizable().scaledToFit()
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let imageView = try inspectable.image()
      XCTAssertTrue(try imageView.isScaledToFit())
      let image = try imageView.actualImage()
      XCTAssertEqual(image.dataRepresentation(), expectedImage.dataRepresentation())
    }

    ViewHosting.host(view: view)
    await fulfillment(of: [expectation])
  }

  func test_initWithCache_contentAndPlaceholder_showsPlaceholder() {
    let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)

    var view = RemoteImage(url: .cuteDoggoPicture, cache: cache) { image in
      image
    } placeholder: {
      ProgressView()
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      XCTAssertNotNil(try inspectable.progressView())
    }

    ViewHosting.host(view: view)
    wait(for: [expectation])
  }

  func test_initWithCache_contentAndPlaceholder_showsLoadedImage() async throws {
    let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)
    let configuration = URLSessionConfiguration.ephemeral
    configuration.urlCache = cache
    let urlSession = createURLSession(configuration: configuration)

    let expectedImage = try await urlSession.fetchImage(from: .cuteDoggoPicture)
    var view = RemoteImage(url: .cuteDoggoPicture, cache: cache) { image in
      image
    } placeholder: {
      ProgressView()
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let image = try inspectable.image().actualImage()
      XCTAssertEqual(image.dataRepresentation(), expectedImage.dataRepresentation())
    }

    ViewHosting.host(view: view)
    await fulfillment(of: [expectation])
  }

  func test_initWithCache_contentPlaceholderFailure_showsPlaceholder() {
    let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)

    var view = RemoteImage(url: .cuteDoggoPicture, cache: cache) { image in
      image
    } placeholder: {
      ProgressView()
    } failure: { _ in
      Text("Failed to load image.")
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      XCTAssertNotNil(try inspectable.progressView())
    }

    ViewHosting.host(view: view)
    wait(for: [expectation])
  }

  func test_initWithCache_contentPlaceholderFailure_showsFailure() async throws {
    let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)
    let configuration = URLSessionConfiguration.ephemeral
    configuration.urlCache = cache
    let urlSession = createURLSession(configuration: configuration)

    _ = try await urlSession.data(from: .invalidImage)
    var view = RemoteImage(url: .invalidImage, cache: cache) { image in
      image
    } placeholder: {
      ProgressView()
    } failure: { _ in
      Text("Failed to load image.")
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let viewModel = try inspectable.actualView().model
      viewModel.phase = .failure(URLError(.unsupportedURL))
      let text = try inspectable.text()
      XCTAssertEqual(try text.string(), "Failed to load image.")
    }

    ViewHosting.host(view: view)
    await fulfillment(of: [expectation])
  }

  func test_initWithCache_contentPlaceholderFailure_showsLoadedImage() async throws {
    let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)
    let configuration = URLSessionConfiguration.ephemeral
    configuration.urlCache = cache
    let urlSession = createURLSession(configuration: configuration)

    let expectedImage = try await urlSession.fetchImage(from: .cuteDoggoPicture)
    var view = RemoteImage(url: .cuteDoggoPicture, cache: cache) { image in
      image
    } placeholder: {
      ProgressView()
    } failure: { _ in
      Text("Failed to load image.")
    }

    let expectation = view.on(\.didAppear) { inspectable in
      XCTAssertEqual(inspectable.count, 1)
      let image = try inspectable.image().actualImage()
      XCTAssertEqual(image.dataRepresentation(), expectedImage.dataRepresentation())
    }

    ViewHosting.host(view: view)
    await fulfillment(of: [expectation])
  }

  // MARK: Private

  private var urlSession: URLSession! // swiftlint:disable:this implicitly_unwrapped_optional

  private func createURLSession(configuration: URLSessionConfiguration = .ephemeral) -> URLSession {
    .stubbed(
      responseProvider: RemoteImageStubbedURL.self,
      configuration: configuration
    )
  }

}
