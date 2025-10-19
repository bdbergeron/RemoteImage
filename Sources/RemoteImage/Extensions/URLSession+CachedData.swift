// Created by Brad Bergeron on 9/17/23.

import Foundation

// MARK: - URLSession + cachedData

extension URLSession {
  /// Create a data task for the given `URL`, returning a response that includes cache hit information.
  /// - Parameter url: `URL` to load data from.
  /// - Parameter skipCache: Whether or not to skip loading data from the local cache.
  /// - Returns: A tuple that contains the `Data` from the response, along with the `URLResponse` itself
  /// and whether or not the response was served from the underlying `URLCache`.
  func data(
    from url: URL,
    skipCache: Bool)
    async throws
    -> (data: Data, urlResponse: URLResponse, didLoadFromCache: Bool)
  {
    let request = URLRequest(
      url: url,
      cachePolicy: skipCache ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy)
    let cacheListener = CacheListener()
    let (data, urlResponse) = try await data(for: request, delegate: cacheListener)
    return (data, urlResponse, cacheListener.didLoadFromCache)
  }
}

// MARK: - CacheListener

/// Utility class that serves as a `URLSessionTaskDelegate` for the purpose of capturing response metrics.
final private class CacheListener: NSObject, URLSessionTaskDelegate {
  var didLoadFromCache = false

  func urlSession(
    _: URLSession,
    task _: URLSessionTask,
    didFinishCollecting metrics: URLSessionTaskMetrics)
  {
    didLoadFromCache = metrics.transactionMetrics.last?.resourceFetchType == .localCache
  }
}
