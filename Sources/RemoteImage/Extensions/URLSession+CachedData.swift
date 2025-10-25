// Created by Brad Bergeron on 9/17/23.

import Foundation
import os

// MARK: - URLSession + cachedData

extension URLSession {
  /// Create a data task for the given `URL`, returning a response that includes cache hit information.
  /// - Parameter url: `URL` to load data from.
  /// - Parameter skipCache: Whether or not to skip loading data from the local cache.
  /// - Returns: A tuple that contains the `Data` from the response, along with the `URLResponse` itself
  /// and whether or not the response was served from the underlying `URLCache`.
  func data(
    from url: URL,
    skipCache: Bool
  ) async throws -> (data: Data, urlResponse: URLResponse, didLoadFromCache: Bool) {
    let request = URLRequest(
      url: url,
      cachePolicy: skipCache ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy
    )
    let cacheListener = CacheListener()
    let (data, urlResponse) = try await data(for: request, delegate: cacheListener)
    let didLoadFromCache = cacheListener.didLoadFromCache.withLock { $0 }
    return (data, urlResponse, didLoadFromCache)
  }
}

// MARK: - CacheListener

/// Utility class that serves as a `URLSessionTaskDelegate` for the purpose of capturing response metrics.
private final class CacheListener: NSObject, URLSessionTaskDelegate {
  let didLoadFromCache = OSAllocatedUnfairLock(uncheckedState: false)

  nonisolated func urlSession(
    _: URLSession,
    task _: URLSessionTask,
    didFinishCollecting metrics: URLSessionTaskMetrics
  ) {
    let resourceFetchType = metrics.transactionMetrics.last?.resourceFetchType
    didLoadFromCache.withLock { $0 = resourceFetchType == .localCache }
  }
}
