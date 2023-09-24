// Created by Brad Bergeron on 8/31/23.

import OSLog
import SwiftUI

// MARK: - RemoteImageConfiguration

/// Configuration parameters for ``RemoteImage/RemoteImage`` instances.
public struct RemoteImageConfiguration {

  // MARK: Lifecycle

  /// Create a new configuration instance.
  /// - Parameters:
  ///   - skipCache: Whether or not to bypass the cache. Default is `false`.
  ///   - scale: The scale to use for the image. The default is `1`. Set a different value when loading images designed for higher resolution displays.
  ///     For example, set a value of `2` for an image that you would name with the `@2x` suffix if stored in a file on disk.
  ///   - transaction: The transaction to use when the phase changes. Default is an empty `Transaction`.
  ///   - disableTransactionWithCachedResponse: Whether or not to disable the ``transaction`` when a cached image is returned.
  ///     Defaults to `true`.
  ///   - logger: An optional `Logger` instance that will be used internally. Defaults to one that utilizes the "io.github.bdbergeron.RemoteImage" subsystem
  ///     and "RemoteImage" category.
  public init(
    skipCache: Bool = false,
    scale: CGFloat = 1.0,
    transaction: Transaction = .init(),
    disableTransactionWithCachedResponse: Bool = true,
    logger: Logger? = .init(subsystem: "io.github.bdbergeron.RemoteImage", category: "RemoteImage"))
  {
    self.skipCache = skipCache
    self.scale = scale
    self.transaction = transaction
    self.disableTransactionWithCachedResponse = disableTransactionWithCachedResponse
    self.logger = logger
  }

  // MARK: Internal

  let skipCache: Bool
  let scale: CGFloat
  let transaction: Transaction
  let disableTransactionWithCachedResponse: Bool
  let logger: Logger?

}

// MARK: - RemoteImagePhase

/// The current phase of the associated ``RemoteImage/RemoteImage`` view.
public enum RemoteImagePhase {

  /// An image has yet to load or the URL is `nil`.
  case placeholder

  /// An image has been successfully loaded.
  case loaded(Image)

  /// An image failed to load.
  case failure(Error)

  /// The current image, if any.
  var image: Image? {
    switch self {
    case .loaded(let image):
      return image
    case .placeholder, .failure:
      return nil
    }
  }
}

// MARK: - RemoteImage

/// An alternative to `AsyncImage` that provides more control around caching and customization.
public struct RemoteImage<Content: View>: View {

  // MARK: Lifecycle

  /// Initialize a new `RemoteImage` instance.
  /// - Parameters:
  ///   - url: The URL of the image to display.
  ///   - urlSession: Optional ``URLSession`` to use for fetching the remote image. If not specified, the ``URLSession.shared`` singleton is used.
  ///   - configuration: Configuration options to use. If none is provided, defaults values are used. See ``RemoteImageConfiguration``.
  ///   - content: A closure that takes the load phase as an input, and returns the view to display for the specified phase.
  public init(
    url: URL?,
    urlSession: URLSession = .shared,
    configuration: RemoteImageConfiguration = .init(),
    @ViewBuilder content: @escaping (RemoteImagePhase) -> Content)
  {
    self.init(
      model: RemoteImageViewModel(
        url: url,
        urlSession: urlSession,
        configuration: configuration),
      content: content)
  }

  /// Initialize a new `RemoteImage` instance using either the fetched remote image or an empty fallback.
  /// - Parameters:
  ///   - url: The URL of the image to display.
  ///   - urlSession: Optional ``URLSession`` to use for fetching the remote image. If not specified, the ``URLSession.shared`` singleton is used.
  ///   - configuration: Configuration options to use. If none is provided, defaults values are used. See ``RemoteImageConfiguration``.
  public init(
    url: URL?,
    urlSession: URLSession = .shared,
    configuration: RemoteImageConfiguration = .init())
    where
    Content == _ConditionalContent<Image, Image>
  {
    self.init(
      url: url,
      urlSession: urlSession,
      configuration: configuration,
      content: Self.imageForPhaseOrEmpty)
  }

  /// Initialize a new `RemoteImage` instance, using either the fetched remote image or an empty fallback,
  /// and calling the provided `content` closure to optionally modify the image.
  /// - Parameters:
  ///   - url: The URL of the image to display.
  ///   - urlSession: Optional ``URLSession`` to use for fetching the remote image. If not specified, the ``URLSession.shared`` singleton is used.
  ///   - configuration: Configuration options to use. If none is provided, defaults values are used. See ``RemoteImageConfiguration``.
  ///   - content: A closure that allows for customization/modification of the loaded image.
  public init<I: View>(
    url: URL?,
    urlSession: URLSession = .shared,
    configuration: RemoteImageConfiguration = .init(),
    @ViewBuilder content: @escaping (Image) -> I)
    where
    Content == _ConditionalContent<I, Image>
  {
    self.init(
      url: url,
      urlSession: urlSession,
      configuration: configuration)
    { image in
      content(image)
    } placeholder: {
      Image(nativeImage: .init())
    }
  }

  /// Initialize a new `RemoteImage` instance using a custom placeholder.
  /// - Parameters:
  ///   - url: The URL of the image to display.
  ///   - urlSession: Optional ``URLSession`` to use for fetching the remote image. If not specified, the ``URLSession.shared`` singleton is used.
  ///   - configuration: Configuration options to use. If none is provided, defaults values are used. See ``RemoteImageConfiguration``.
  ///   - content: A closure that takes the loaded image as an input, and returns the view to show. You can return the image directly, or modify it as needed
  ///     before returning it.
  ///   - placeholder: A closure that returns the view to show until the load operation completes successfully.
  public init<I, P>(
    url: URL?,
    urlSession: URLSession = .shared,
    configuration: RemoteImageConfiguration = .init(),
    @ViewBuilder content: @escaping (Image) -> I,
    @ViewBuilder placeholder: @escaping () -> P)
    where
    Content == _ConditionalContent<I, P>,
    I: View,
    P: View
  {
    self.init(
      url: url,
      urlSession: urlSession,
      configuration: configuration)
    { phase in
      Self.imageForPhaseOrPlaceholder(
        phase,
        content: content,
        placeholder: placeholder)
    }
  }

  /// Initialize a new `RemoteImage` instance using a custom placeholder and failure view.
  /// - Parameters:
  ///   - url: The URL of the image to display.
  ///   - cache: Cache to use with the underlying ``URLSession``.
  ///   - urlSession: Optional ``URLSession`` to use for fetching the remote image. If not specified, the ``URLSession.shared`` singleton is used.
  ///   - configuration: Configuration options to use. If none is provided, defaults values are used. See ``RemoteImageConfiguration``.
  ///   - content: A closure that takes the loaded image as an input, and returns the view to show. You can return the image directly, or modify it as needed
  ///     before returning it.
  ///   - placeholder: A closure that returns the view to show until the load operation completes successfully.
  ///   - failure: A closure that returns a view to show if the image fails to load.
  public init<I, P, F>(
    url: URL?,
    urlSession: URLSession = .shared,
    configuration: RemoteImageConfiguration = .init(),
    @ViewBuilder content: @escaping (Image) -> I,
    @ViewBuilder placeholder: @escaping () -> P,
    @ViewBuilder failure: @escaping (Error) -> F)
    where
    Content == _ConditionalContent<_ConditionalContent<P, I>, F>,
    I: View,
    P: View,
    F: View
  {
    self.init(
      url: url,
      urlSession: urlSession,
      configuration: configuration)
    { phase in
      Self.contentForPhase(
        phase,
        content: content,
        placeholder: placeholder,
        failure: failure)
    }
  }

  // MARK: Public

  /// The content and behavior of the view.
  public var body: some View {
    content(model.phase)
      .onAppear {
        model.onAppear()
        didAppear?(self)
      }
      .onDisappear {
        model.onDisappear()
      }
  }

  // MARK: Internal

  init(
    model: RemoteImageViewModel,
    @ViewBuilder content: @escaping (RemoteImagePhase) -> Content)
  {
    _model = .init(wrappedValue: model)
    self.content = content
  }

  @StateObject var model: RemoteImageViewModel

  var didAppear: ((Self) -> Void)?

  // MARK: Private

  private var content: (RemoteImagePhase) -> Content

}

#if DEBUG

// MARK: - RemoteImage_Previews

struct RemoteImage_Previews: PreviewProvider {

  // MARK: Internal

  static var previews: some View {
    remoteImage(
      url: imageURL)
      .previewDisplayName("Cached")
      .previewLayout(.sizeThatFits)

    remoteImage(
      url: imageURL,
      skipCache: true)
      .previewDisplayName("Skip Cache")
      .previewLayout(.sizeThatFits)

    remoteImage(
      url: .init(string: "https://www.example.com"))
      .previewDisplayName("Failure")
      .previewLayout(.sizeThatFits)

    remoteImage(
      url: imageURL,
      skipCache: true,
      placeholder: {
        ZStack {
          EmptyView()
        }
      })
      .previewDisplayName("Empty Placeholder")
      .previewLayout(.sizeThatFits)
  }

  // MARK: Private

  private static let imageURL = URL(
    string: "https://fastly.picsum.photos/id/237/1000/1000.jpg?hmac=5nME13-xBzl4yi2t1tFev6zsf5IWO2-efZAoXEm9ltc")!

  private static func remoteImage(
    url: URL?,
    urlSession: URLSession = .shared,
    skipCache: Bool = false)
    -> some View
  {
    remoteImage(
      url: url,
      urlSession: urlSession,
      skipCache: skipCache) 
    {
      ZStack {
        Color(white: 0.8)
        ProgressView()
          .tint(.white)
      }
    } failure: { _ in
      ZStack {
        Color.yellow
        Image(systemName: "exclamationmark.triangle")
          .font(.largeTitle)
          .foregroundStyle(.white)
      }
    }
  }

  private static func remoteImage(
    url: URL?,
    urlSession: URLSession = .shared,
    skipCache: Bool = false,
    @ViewBuilder placeholder: @escaping () -> some View = EmptyView.init,
    @ViewBuilder failure: @escaping (Error) -> some View = { _ in EmptyView() })
    -> some View
  {
    GeometryReader { geometry in
      RemoteImage(
        url: url,
        urlSession: urlSession,
        configuration: .init(
          skipCache: skipCache,
          transaction: .init(animation: .easeIn.delay(0.5))))
      { phase in
        switch phase {
        case .loaded(let image):
          image
            .resizable()
            .scaledToFill()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        case .placeholder:
          placeholder()
        case .failure(let error):
          failure(error)
        }
      }
    }
    .aspectRatio(4 / 3, contentMode: .fit)
  }
}

#endif
