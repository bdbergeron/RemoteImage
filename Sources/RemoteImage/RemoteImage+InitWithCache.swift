// Created by Brad Bergeron on 9/23/23.

import SwiftUI

// MARK: - RemoteImage + initWithCache

extension RemoteImage {

  /// Initialize a new `RemoteImage` instance.
  ///
  /// A ``URLSession`` will be constructed using the ``URLSessionConfiguration.default`` configuration and the specified ``cache``.
  /// - Parameters:
  ///   - url: The URL of the image to display.
  ///   - cache: Cache to use with the underlying ``URLSession``.
  ///   - configuration: Configuration options to use. If none is provided, defaults values are used. See ``RemoteImageConfiguration``.
  ///   - content: A closure that takes the load phase as an input, and returns the view to display for the specified phase.
  public init(
    url: URL?,
    cache: URLCache,
    configuration: RemoteImageConfiguration = .init(),
    @ViewBuilder content: @escaping (RemoteImagePhase) -> Content
  ) {
    self.init(
      model: RemoteImageViewModel(
        url: url,
        cache: cache,
        configuration: configuration
      ),
      content: content
    )
  }

  /// Initialize a new `RemoteImage` instance using either the fetched remote image or an empty fallback.
  ///
  /// A ``URLSession`` will be constructed using the ``URLSessionConfiguration.default`` configuration and the specified ``cache``.
  /// - Parameters:
  ///   - url: The URL of the image to display.
  ///   - cache: Cache to use with the underlying ``URLSession``.
  ///   - configuration: Configuration options to use. If none is provided, defaults values are used. See ``RemoteImageConfiguration``.
  public init(
    url: URL?,
    cache: URLCache,
    configuration: RemoteImageConfiguration = .init()
  )
    where
    Content == _ConditionalContent<Image, Image>
  {
    self.init(
      url: url,
      cache: cache,
      configuration: configuration,
      content: Self.imageOrEmpty
    )
  }

  /// Initialize a new `RemoteImage` instance, using either the fetched remote image or an empty fallback, and calling the provided `content` closure
  /// to optionally modify the image.
  ///
  /// A ``URLSession`` will be constructed using the ``URLSessionConfiguration.default`` configuration and the specified ``cache``.
  /// - Parameters:
  ///   - url: The URL of the image to display.
  ///   - cache: Cache to use with the underlying ``URLSession``.
  ///   - configuration: Configuration options to use. If none is provided, defaults values are used. See ``RemoteImageConfiguration``.
  ///   - content: A closure that allows for customization/modification of the loaded image.
  public init<I: View>(
    url: URL?,
    cache: URLCache,
    configuration: RemoteImageConfiguration = .init(),
    @ViewBuilder content: @escaping (Image) -> I
  )
    where
    Content == _ConditionalContent<I, Image>
  {
    self.init(
      url: url,
      cache: cache,
      configuration: configuration
    ) { phase in
      Self.contentForPhase(
        phase,
        content: content,
        placeholder: {
          Image(nativeImage: .init())
        }
      )
    }
  }

  /// Initialize a new `RemoteImage` instance using a custom placeholder.
  ///
  /// A ``URLSession`` will be constructed using the ``URLSessionConfiguration.default`` configuration and the specified ``cache``.
  /// - Parameters:
  ///   - url: The URL of the image to display.
  ///   - cache: Cache to use with the underlying ``URLSession``.
  ///   - configuration: Configuration options to use. If none is provided, defaults values are used. See ``RemoteImageConfiguration``.
  ///   - content: A closure that takes the loaded image as an input, and returns the view to show. You can return the image directly, or modify it as needed
  ///     before returning it.
  ///   - placeholder: A closure that returns the view to show until the load operation completes successfully.
  public init<I, P>(
    url: URL?,
    cache: URLCache,
    configuration: RemoteImageConfiguration = .init(),
    @ViewBuilder content: @escaping (Image) -> I,
    @ViewBuilder placeholder: @escaping () -> P
  )
    where
    Content == _ConditionalContent<I, P>,
    I: View,
    P: View
  {
    self.init(
      url: url,
      cache: cache,
      configuration: configuration
    ) { phase in
      Self.contentForPhase(
        phase,
        content: content,
        placeholder: placeholder
      )
    }
  }

  /// Initialize a new `RemoteImage` instance, calling the provided `content` closure to optionally modify the loaded image.
  /// While the image loads, the `placeholder` is shown. If the image fails to load, `failure` is shown.
  ///
  /// A ``URLSession`` will be constructed using the ``URLSessionConfiguration.default`` configuration and the specified ``cache``.
  /// - Parameters:
  ///   - url: The URL of the image to display.
  ///   - cache: Cache to use with the underlying ``URLSession``.
  ///   - configuration: Configuration options to use. If none is provided, defaults values are used. See ``RemoteImageConfiguration``.
  ///   - content: A closure that takes the loaded image as an input, and returns the view to show. You can return the image directly, or modify it as needed
  ///     before returning it.
  ///   - placeholder: A closure that returns the view to show until the load operation completes successfully.
  ///   - failure: A closure that returns a view to show if the image fails to load.
  public init<I, P, F>(
    url: URL?,
    cache: URLCache,
    configuration: RemoteImageConfiguration = .init(),
    @ViewBuilder content: @escaping (Image) -> I,
    @ViewBuilder placeholder: @escaping () -> P,
    @ViewBuilder failure: @escaping (Error) -> F
  )
    where
    Content == _ConditionalContent<_ConditionalContent<P, I>, F>,
    I: View,
    P: View,
    F: View
  {
    self.init(
      url: url,
      cache: cache,
      configuration: configuration
    ) { phase in
      Self.contentForPhase(
        phase,
        content: content,
        placeholder: placeholder,
        failure: failure
      )
    }
  }
}
