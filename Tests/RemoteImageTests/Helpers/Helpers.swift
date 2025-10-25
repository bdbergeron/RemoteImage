// Created by Brad Bergeron on 9/1/23.

import Foundation
import SwiftUI
import XCTest

@testable import RemoteImage

extension Data {
  /// A picture of a cute doggo. 🐶
  static var cuteDoggo: Data? {
    Bundle.module
      .url(forResource: "Doggo", withExtension: "jpg")
      .flatMap { try? Data(contentsOf: $0) }
  }
}

// MARK: - URL + @retroactive ExpressibleByStringLiteral

extension URL: @retroactive ExpressibleByStringLiteral {

  // MARK: Lifecycle

  /// Allow a URL to be constructed directly from a ``StaticString``.
  /// - Parameter url: URL string representation.
  public init(stringLiteral url: StaticString) {
    guard let url = URL(string: "\(url)") else {
      XCTFail("Invalid URL: \(url)")
      preconditionFailure("Invalid URL: \(url)")
    }
    self = url
  }

  // MARK: Internal

  /// A picture of a cute doggo. 🐶
  static let cuteDoggoPicture: URL = "https://fastly.picsum.photos/id/237/200/200.jpg?hmac=zHUGikXUDyLCCmvyww1izLK3R3k8oRYBRiTizZEdyfI"

  /// A non-image URL.
  static let invalidImage: URL = "https://bdbergeron.github.io"
}

extension URLSession {
  /// Fetch an image.
  /// - Parameters:
  ///   - url: Image URL to fetch.
  ///   - cache: Cache instance to use with URLSession.
  /// - Returns: An ``Image`` instance of the fetched image.
  @discardableResult
  func fetchImage(from url: URL) async throws -> Image {
    let (data, _) = try await data(from: url)
    XCTAssertFalse(data.isEmpty)
    let image = try XCTUnwrap(PlatformNativeImage(data: data))
    return Image(nativeImage: image)
  }
}

extension Image {
  /// Get the data representation of this `Image` instance.
  /// - Parameter scale: Display scale to render the image at.
  /// - Returns: A `Data` representation of this `Image` view.
  @MainActor
  func dataRepresentation(scale: CGFloat = 1.0) -> Data? {
    let renderer = ImageRenderer(content: self)
    renderer.scale = scale
    #if os(iOS)
    return renderer.uiImage?.pngData()
    #elseif os(macOS)
    return renderer.nsImage?.tiffRepresentation
    #endif
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
