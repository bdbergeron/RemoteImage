// Created by Brad Bergeron on 9/1/23.

import Foundation
import SwiftUI
import XCTest

extension Data {
  /// A picture of a cute doggo. 🐶
  static var cuteDoggo: Data? {
    Bundle.module
      .url(forResource: "Doggo", withExtension: "jpg")
      .flatMap { try? Data(contentsOf: $0) }
  }
}

extension URL {
  /// A picture of a cute doggo. 🐶
  static var cuteDoggo: URL {
    URL(string: "https://fastly.picsum.photos/id/237/200/200.jpg?hmac=zHUGikXUDyLCCmvyww1izLK3R3k8oRYBRiTizZEdyfI")!
  }
}

extension URLCache {
  /// Small cache to use with tests.
  static let testCache: URLCache = {
    let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    let cacheDirectory = cacheURL?.appendingPathComponent("RemoteImageTests")
    return URLCache(memoryCapacity: 1_000_000, diskCapacity: 10_000_000, directory: cacheDirectory)
  }()

  func clear() async throws {
    removeAllCachedResponses()
    // The above call is not immediate; sleep a tiny bit to ensure the cache is actually clear for the next test.
    try await Task.sleep(for: .milliseconds(10))
  }
}

extension URLSession {
  /// Fetch and cache an image.
  /// - Parameters:
  ///   - url: Image URL to fetch.
  ///   - cache: Cache instance to use with URLSession.
  @discardableResult
  func fetchAndCacheImage(from url: URL) async throws -> Image {
    let (data, _) = try await data(from: url)
    XCTAssertFalse(data.isEmpty)
    let image = try XCTUnwrap(UIImage(data: data))
    return Image(uiImage: image)
  }
}

extension Image {
  /// Convert this `Image` view to a `UIImage`. Workaround for not having access to the underlying `UIImage` instance itself.
  /// - Parameter scale: Display scale to render the image at.
  /// - Returns: `UIImage` representation of this `Image` view.
  @MainActor
  func uiImageRepresentation(scale: CGFloat = 1.0) -> UIImage? {
    let renderer = ImageRenderer(content: self)
    renderer.scale = scale
    return renderer.uiImage
  }

  func snapshot(origin: CGPoint = .zero, size: CGSize) -> UIImage {
    let window = UIWindow(frame: CGRect(origin: origin, size: size))
    let hostingController = UIHostingController(rootView: self)
    hostingController.view.frame = window.frame
    window.addSubview(hostingController.view)
    window.makeKeyAndVisible()

    UIGraphicsBeginImageContextWithOptions(hostingController.view.bounds.size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()!
    hostingController.view.layer.render(in: context)
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return image
  }
}

#if TEST
extension Bundle {
  static let module: Bundle = {
    let bundleName = "RemoteImage_RemoteImageTests"
    let candidates = [
      // Bundle should be present here when the package is linked into an App.
      Bundle.main.resourceURL,
      // Bundle should be present here when the package is linked into a framework.
      Bundle(for: RemoteImageTests.self).resourceURL,
      // For command-line tools.
      Bundle.main.bundleURL,
    ]
    for candidate in candidates {
      let bundlePath = candidate?.appendingPathComponent("\(bundleName).bundle")
      if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
        return bundle
      }
    }
    return Bundle(for: RemoteImageTests.self)
  }()
}
#endif
