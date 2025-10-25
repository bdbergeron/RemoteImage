// Created by Brad Bergeron on 9/23/23.

import RemoteImage
import SwiftUI

// MARK: - DemosList

struct DemosList: View {

  // MARK: Internal

  @State var selectedVariant: Variant?

  enum Variant: String, CaseIterable {
    /// A simple `RemoteImage` view.
    case simple = "Simple"

    /// A simple `RemoteImage` view with modifier closure.
    case simpleWithModifier = "Simple, with image modifier"

    /// A `RemoteImage` view with a custom placeholder.
    case customPlaceholder = "Custom placeholder"

    /// A `RemoteImage` view with custom failure.
    case customFailure = "Custom failure"

    /// Image loaded with a custom `URLSession` and using a custom phase transition animation.
    case customURLSession = "Custom URLSession"

    /// Image loaded from a custom cache. If the image is not yet cached, a new `URLSession`
    /// will be constructed using the `URLSessionConfiguration.default` configuration
    /// and the provided cache instance.
    case customCache = "Custom Cache"
  }

  var body: some View {
    NavigationStack {
      List {
        ForEach(Variant.allCases, id: \.rawValue) { variant in
          Button(variant.rawValue) {
            selectedVariant = variant
          }
          .tint(.primary)
        }
      }
      .navigationDestination(item: $selectedVariant) { variant in
        ScrollView {
          VStack {
            content(for: variant)
              .frame(maxWidth: .infinity)
          }
        }
        .navigationTitle(variant.rawValue)
        .navigationBarTitleDisplayMode(.inline)
      }
      .navigationTitle("RemoteImage Demos")
    }
  }

  // MARK: Private

  @ViewBuilder
  private func content(for variant: Variant) -> some View {
    switch variant {
    case .simple:
      RemoteImage(url: .cuteDoggo) {
        $0.resizable().scaledToFit()
      }

    case .simpleWithModifier:
      RemoteImage(url: .cuteDoggo) {
        $0.resizable().saturation(0.1).scaledToFit()
      }

    case .customPlaceholder:
      RemoteImage(
        url: .cuteDoggo,
        configuration: .init(
          skipCache: true,
          animation: .spring(duration: 1.0).delay(0.5)))
      {
        $0.resizable().scaledToFit()
      } placeholder: {
        ZStack {
          Color.black.opacity(0.05)
          ProgressView()
        }
        .aspectRatio(1, contentMode: .fit)
      }

    case .customFailure:
      RemoteImage(
        url: .githubRepo,
        configuration: .init(
          animation: .spring(duration: 1.0).delay(0.5)))
      {
        $0.resizable().scaledToFit()
      } placeholder: {
        ZStack {
          Color.black.opacity(0.05)
          ProgressView()
        }
        .aspectRatio(1, contentMode: .fit)
      } failure: { _ in
        ZStack {
          Color.yellow.opacity(0.3)
          VStack(spacing: 12) {
            Image(systemName: "photo")
              .resizable()
              .scaledToFit()
              .frame(width: 32)
            Text("Image could not be loaded.")
          }
          .font(.headline.weight(.regular))
          .foregroundStyle(.secondary)
        }
        .aspectRatio(1, contentMode: .fit)
      }

    case .customURLSession:
      RemoteImage(
        url: .cuteDoggo,
        urlSession: .init(
          configuration: .ephemeral),
        configuration: .init(
          animation: .spring(duration: 1.0).delay(0.5)))
      {
        $0.resizable().scaledToFit()
      }

    case .customCache:
      RemoteImage(
        url: .cuteDoggo,
        cache: .inMemoryOnly,
        configuration: .init(
          animation: .spring(duration: 1.0).delay(0.5)))
      {
        $0.resizable().scaledToFit()
      } placeholder: {
        ZStack {
          Color.black.opacity(0.05)
          ProgressView()
        }
        .aspectRatio(1, contentMode: .fit)
      }
    }
  }
}

extension URL {
  fileprivate static let cuteDoggo = URL(string: "https://fastly.picsum.photos/id/237/1000/1000.jpg?hmac=5nME13-xBzl4yi2t1tFev6zsf5IWO2-efZAoXEm9ltc")!

  fileprivate static let githubRepo = URL(string: "https://github.com/bdbergeron/RemoteImage")!
}

extension URLCache {
  static let inMemoryOnly = URLCache(memoryCapacity: 10_000_000, diskCapacity: 0)
}

#if DEBUG
// MARK: - DemosListPreviews

struct DemosListPreviews: PreviewProvider {
  static var previews: some View {
    DemosList()
  }
}
#endif
