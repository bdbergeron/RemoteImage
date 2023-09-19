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
  ///   - skipCache: Whether or not to bypass the cache. Default is `false`.
  ///   - scale: Image scale. Default is `1.0`.
  ///   - transaction: Transaction used during image phase changes. Default is an empty instance.
  ///   - disableTransactionWithCachedResponse: Whether or not to disable the ``transaction`` when a cached image is returned. Defaults to `true`.
  init(
    url: URL?,
    urlSession: URLSession = .shared,
    skipCache: Bool = false,
    scale: CGFloat = 1.0,
    transaction: Transaction = .init(),
    disableTransactionWithCachedResponse: Bool = true)
  {
    self.url = url
    self.urlSession = urlSession
    self.skipCache = skipCache
    self.scale = scale
    self.transaction = transaction
    self.disableTransactionWithCachedResponse = disableTransactionWithCachedResponse
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

  /// Image scale.
  let scale: CGFloat

  /// Transaction used during image phase changes.
  let transaction: Transaction

  /// Whether or not to disable the ``transaction`` when a cached image is returned.
  let disableTransactionWithCachedResponse: Bool

  /// The current image phase.
  @Published private(set) var phase: RemoteImagePhase = .placeholder

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
  }

  /// Load the image if needed.
  ///
  /// If the current ``phase`` is not ``RemoteImagePhase/placeholder``, we simply return. If the ``url`` is `nil`,
  /// we set ``phase`` to ``RemoteImagePhase/placeholder`` and return. Otherwise, we attempt to load the remote image.
  func loadImageIfNeeded() async {
    // Ensure the image phase is `.placeholder` and we have a valid `URL` to load.
    guard
      case .placeholder = phase,
      let url
    else {
      logger.debug("Image phase was not .placeholder, or image URL was nil. Skipping image load.")
      return
    }
    // Perform network fetch.
    logger.debug("Loading remote image...")
    do {
      let (data, _, didLoadFromCache) = try await urlSession.cachedData(from: url, skipCache: skipCache)
      logger.debug("Image loaded with \(data.count) bytes. From cache: \(didLoadFromCache).")
      let image = try createImage(with: data)
      let disableAnimation = didLoadFromCache && disableTransactionWithCachedResponse
      logger.debug("Setting phase to .loaded. Animated: \(!disableAnimation).")
      setPhase(.loaded(image), animated: !disableAnimation)
    } catch {
      logger.error("Failed to load remote image: \(error.localizedDescription)")
      setPhase(.failure(error), animated: true)
    }
  }

  /// Create an ``Image`` instance with the provided image ``data``.
  ///
  /// Throws ``Error/invalidImageData`` if the data is invalid or corrupted.
  ///
  /// - Parameter data: Image data.
  /// - Returns: An ``Image`` instance.
  func createImage(with data: Data) throws -> Image {
    guard let image = UIImage(data: data, scale: scale) else {
      logger.error("Could not create a UIImage instance from data (\(data)).")
      throw Error.invalidImageData
    }
    return Image(uiImage: image)
  }

  // MARK: Private

  private let logger = Logger(
    subsystem: "io.github.bdbergeron.RemoteImage",
    category: String(describing: RemoteImageViewModel.self))

  private var loadingTask: Task<Void, Swift.Error>?

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
  ///   - skipCache: Whether or not to bypass the cache.
  ///   - scale: Image scale.
  ///   - transaction: Transaction used during image phase changes.
  ///   - disableTransactionWithCachedResponse: Whether or not to disable the ``transaction`` when a cached image is returned.
  convenience init(
    url: URL?,
    cache: URLCache,
    skipCache: Bool = false,
    scale: CGFloat = 1.0,
    transaction: Transaction = .init(),
    disableTransactionWithCachedResponse: Bool = true)
  {
    let configuration = URLSessionConfiguration.default
    configuration.urlCache = cache
    let urlSession = URLSession(configuration: configuration)

    self.init(
      url: url,
      urlSession: urlSession,
      skipCache: skipCache,
      scale: scale,
      transaction: transaction,
      disableTransactionWithCachedResponse: disableTransactionWithCachedResponse)
  }
}
