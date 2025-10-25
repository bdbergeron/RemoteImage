// Created by Brad Bergeron on 9/23/23.

import SwiftUI

// MARK: - RemoteImageViewModel + initWithCache

extension RemoteImageViewModel {
  /// Create a new ``RemoteImageViewModel`` instance.
  ///
  /// A ``URLSession`` will be constructed using the ``URLSessionConfiguration.default`` configuration and the specified ``cache``.
  /// - Parameters:
  ///   - url: Image URL.
  ///   - cache: Cache instance to use.
  ///   - configuration: A ``RemoteImageConfiguration`` object to use for configuring this model.
  convenience init(
    url: URL?,
    cache: URLCache,
    configuration: RemoteImageConfiguration
  ) {
    self.init(
      url: url,
      urlSession: URLSession(
        configuration: {
          let configuration = URLSessionConfiguration.default
          configuration.urlCache = cache
          return configuration
        }()),
      configuration: configuration
    )
  }
}
