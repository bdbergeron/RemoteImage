// Created by Brad Bergeron on 9/10/23.

import Foundation
import XCTest

#if DEBUG || TEST

// MARK: - MockURLProtocol

final class MockURLProtocol: URLProtocol {

  // MARK: Internal

  override class func canInit(with _: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let requestHandler = Self.requestHandler else {
      client?.urlProtocol(self, didFailWithError: MockURLProtocolError.requestHandlerNotConfigured)
      return
    }
    do {
      let (response, data) = try requestHandler(request)
      if let response {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
      }
      if let data {
        client?.urlProtocol(self, didLoad: data)
      }
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() { }

  // MARK: Fileprivate

  fileprivate static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse?, Data?))?

}

extension MockURLProtocol {
  static func configureRequestHandler(
    with data: Data?,
    httpStatusCode: Int = 200)
    throws
  {
    Self.requestHandler = { request in
      let response = HTTPURLResponse(
        url: try XCTUnwrap(request.url),
        statusCode: httpStatusCode,
        httpVersion: nil,
        headerFields: nil)
      return (response, data)
    }
  }

  static func configureRequestHandlerWithError() {
    Self.requestHandler = { _ in
      throw MockURLProtocolError.error
    }
  }

  static func configureWithCancelledRequest() {
    Self.requestHandler = { _ in
      throw URLError(.cancelled)
    }
  }

  static func resetRequestHandler() {
    Self.requestHandler = nil
  }
}

// MARK: - MockURLProtocolError

enum MockURLProtocolError: Error {
  case requestHandlerNotConfigured
  case error
}

#endif
