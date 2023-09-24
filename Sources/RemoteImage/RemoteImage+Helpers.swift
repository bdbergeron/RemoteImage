// Created by Brad Bergeron on 9/23/23.

import SwiftUI

extension RemoteImage {
  /// Get an `Image` view for the loaded image, otherwise get an empty placeholder view.
  /// - Parameter phase: The current ``RemoteImagePhase``.
  /// - Returns: If the current `phase` is ``RemoteImagePhase/loaded``, returns an `Image` instance with the loaded image.
  ///   Otherwise, and empty image will be used.
  @ViewBuilder
  static func imageOrEmpty(
    _ phase: RemoteImagePhase)
    -> Content
    where
    Content == _ConditionalContent<Image, Image>
  {
    if let image = phase.image {
      image
    } else {
      Image(nativeImage: .init())
    }
  }

  /// Get a view for the loaded image. If the image is loading, the placeholder view is shown.
  /// - Parameters:
  ///   - phase: The current ``RemoteImagePhase``.
  ///   - content: A closure that operates on the loaded image, allowing for customization/manipulation of the loaded image.
  ///   - placeholder: A view used as the placeholder.
  /// - Returns: If the current `phase` is ``RemoteImagePhase/loaded``, returns an `Image` instance with the loaded image.
  ///   Otherwise, return the placeholder view.
  @ViewBuilder
  static func contentForPhase<I, P>(
    _ phase: RemoteImagePhase,
    @ViewBuilder content: @escaping (Image) -> I,
    @ViewBuilder placeholder: @escaping () -> P)
    -> Content
    where
    Content == _ConditionalContent<I, P>,
    I: View,
    P: View
  {
    if let image = phase.image {
      content(image)
    } else {
      placeholder()
    }
  }

  /// Get a view for the loaded image. If the image is loading, the placeholder view is shown. If the image failed to load, the failure view is shown.
  /// - Parameters:
  ///   - phase: The current ``RemoteImagePhase``.
  ///   - content: A closure that operates on the loaded image, allowing for customization/manipulation of the loaded image.
  ///   - placeholder: A view used as the placeholder.
  ///   - failure: A view used if the image fails to load.
  /// - Returns: If the current `phase` is ``RemoteImagePhase/loaded``, returns an `Image` instance with the loaded image.
  ///   Otherwise, return the placeholder view.
  @ViewBuilder
  static func contentForPhase<I, P, F>(
    _ phase: RemoteImagePhase,
    @ViewBuilder content: @escaping (Image) -> I,
    @ViewBuilder placeholder: @escaping () -> P,
    @ViewBuilder failure: @escaping (Error) -> F)
    -> Content
    where
    Content == _ConditionalContent<_ConditionalContent<P, I>, F>,
    I: View,
    P: View,
    F: View
  {
    switch phase {
    case .placeholder:
      placeholder()
    case .loaded(let image):
      content(image)
    case .failure(let error):
      failure(error)
    }
  }
}
