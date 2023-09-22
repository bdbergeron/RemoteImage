// Created by Brad Bergeron on 9/3/23.

import Combine
import OSLog
import SwiftUI

// MARK: - RemoteImageViewModel

/// View model used with ``RemoteImage``.
@MainActor
final class RemoteImageViewModel: ObservableObject {

  // MARK: Lifecycle

  /// Create a new ``RemoteImageViewModel`` instance.
  /// - Parameters:
  ///   - url: Image URL.
  ///   - urlSession: ``URLSession`` instance to use for remote image fetching and caching.
  ///   - configuration: A ``RemoteImageConfiguration`` object to use for configuring this model.
  init(
    url: URL?,
    urlSession: URLSession = .shared,
    configuration: RemoteImageConfiguration = .init())
  {
    self.url = url
    self.urlSession = urlSession
    self.skipCache = configuration.skipCache
    self.scale = configuration.scale
    self.transaction = configuration.transaction
    self.disableTransactionWithCachedResponse = configuration.disableTransactionWithCachedResponse
    self.logger = configuration.logger
  }

  // MARK: Internal

  /// Errors thrown by ``RemoteImageViewModel``.
  enum Error: LocalizedError {
    /// Image data was invalid or corrupted.
    case invalidImageData
  }

  /// Image URL.
  let url: URL?

  /// ``URLSession`` instance to use for remote image fetching and caching.
  let urlSession: URLSession

  /// Whether or not to bypass the cache.
  let skipCache: Bool

  /// The scale to use for the image.
  let scale: CGFloat

  /// The transaction to use when the phase changes.
  let transaction: Transaction

  /// Whether or not to disable the ``transaction`` when a cached image is returned.
  let disableTransactionWithCachedResponse: Bool
  
  /// An optional `Logger` instance that will be used internally.
  let logger: Logger?

  /// The current image phase.
  @Published private(set) var phase: RemoteImagePhase = .placeholder

  var loadingTask: Task<Void, Swift.Error>?

  /// Retrieve the cache used by ``urlSession``.
  var cache: URLCache? {
    urlSession.configuration.urlCache
  }

  /// The cached image, if one exists.
  var cachedImage: Image? {
    guard
      !skipCache,
      let url,
      let cache
    else {
      return nil
    }
    let request = URLRequest(url: url)
    guard let imageData = cache.cachedResponse(for: request)?.data else {
      return nil
    }
    return try? createImage(with: imageData)
  }

  /// When the view owning this model appears, load the image from either the local cache or remote URL.
  func onAppear() {
    if case .loaded = phase {
      return
    }
    if
      !skipCache,
      let cachedImage
    {
      setPhase(.loaded(cachedImage), animated: false)
      return
    }
    loadingTask = Task {
      await loadImageIfNeeded()
    }
  }

  /// When the view owning this model disappears, cancel any in-flight remote image load.
  func onDisappear() {
    loadingTask?.cancel()
    loadingTask = nil
  }

  /// Create an ``Image`` instance with the provided image ``data``.
  ///
  /// Throws ``Error/invalidImageData`` if the data is invalid or corrupted.
  ///
  /// - Parameter data: Image data.
  /// - Returns: An ``Image`` instance.
  func createImage(with data: Data) throws -> Image {
    guard let image = PlatformNativeImage(data: data, scale: scale) else {
      logger?.error("Could not create a \(PlatformNativeImage.self) instance from data (\(data)).")
      throw Error.invalidImageData
    }
    return Image(nativeImage: image)
  }

  // MARK: Private

  /// Load the image if needed.
  ///
  /// If the `url` is `nil`, we set ``phase`` to ``RemoteImagePhase/placeholder`` and return. Otherwise, we attempt to load the remote image.
  private func loadImageIfNeeded() async {
    guard let url else {
      logger?.debug("Image URL is nil, skipping image load.")
      return
    }
    // Perform network fetch.
    logger?.debug("Loading image from \(url)...")
    do {
      let (data, _, didLoadFromCache) = try await urlSession.cachedData(from: url, skipCache: skipCache)
      try Task.checkCancellation()
      logger?.debug("Image loaded from \(url) with \(data.count) bytes. From cache: \(String(describing: didLoadFromCache)).")
      let image = try createImage(with: data)
      try Task.checkCancellation()
      let disableAnimation = didLoadFromCache && disableTransactionWithCachedResponse
      logger?.debug("Setting phase to .loaded for \(url). Animated: \(String(describing: !disableAnimation)).")
      setPhase(.loaded(image), animated: !disableAnimation)
    } catch URLError.cancelled {
      logger?.debug("Cancelled loading image from \(url).")
      setPhase(.placeholder, animated: false)
    } catch {
      logger?.error("Failed to load image from \(url): \(error.localizedDescription)")
      setPhase(.failure(error), animated: true)
    }
    loadingTask = nil
  }

  /// Set the image phase.
  /// - Parameters:
  ///   - phase: New image phase.
  ///   - animated: Whether or not to animate the phase change.
  private func setPhase(_ phase: RemoteImagePhase, animated: Bool) {
    guard animated else {
      self.phase = phase
      return
    }
    withAnimation(transaction.animation) {
      self.phase = phase
    }
  }

}

// MARK: initWithCache

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
    configuration: RemoteImageConfiguration)
  {
    self.init(
      url: url,
      urlSession: URLSession(
        configuration: {
          let configuration = URLSessionConfiguration.default
          configuration.urlCache = cache
          return configuration
        }()),
      configuration: configuration)
  }
}
