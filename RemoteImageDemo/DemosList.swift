// Created by Brad Bergeron on 9/23/23.

import RemoteImage
import SwiftUI

// MARK: - DemosList

struct DemosList: View {

  // MARK: Internal

  var body: some View {
    NavigationStack {
      List {
        ForEach(Variant.allCases, id: \.rawValue) { variant in
          NavigationLink(variant.rawValue, value: variant)
        }
      }
      .navigationDestination(for: Variant.self) { variant in
        List {
          VStack {
            content(for: variant)
          }
          .frame(maxWidth: .infinity)
          .listRowInsets(.init())
          .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .listSectionSeparator(.hidden)
        .navigationTitle(variant.rawValue)
        .navigationBarTitleDisplayMode(.inline)
      }
      .navigationTitle("RemoteImage Demos")
    }
  }

  // MARK: Private

  private enum Variant: String, CaseIterable {
    /// A simple `RemoteImage` view.
    case simple = "Simple"

    /// A simple `RemoteImage` view with modifier closure.
    case simpleWithModifier = "Simple, with image modifier"

    /// A `RemoteImage` view with a custom placeholder.
    case customPlaceholder = "Custom placeholder"

    /// A `RemoteImage` view with custom content.
    case customContent = "Custom content"

    /// Image loaded with a custom `URLSession`, skipping the cache, and using a custom
    /// phase transition animation.
    case customURLSession = "Custom URLSession"

    /// Image loaded from a custom cache. If the image is not yet cached, a new `URLSession`
    /// will be constructed using the `URLSessionConfiguration.default` configuration
    /// and the provided cache instance.
    case customCache = "Custom Cache"
  }

  @ViewBuilder
  private func content(for variant: Variant) -> some View {
    switch variant {
    case .simple:
      RemoteImage(url: .cuteDoggo)

    case .simpleWithModifier:
      RemoteImage(url: .cuteDoggo) {
        $0.resizable().scaledToFit()
      }

    case .customPlaceholder:
      RemoteImage(url: nil) { image in
        image.resizable().scaledToFit()
      } placeholder: {
        ProgressView()
      }

    case .customContent:
      RemoteImage(url: .githubRepo) { phase in
        switch phase {
        case .placeholder:
          ProgressView()
        case .loaded(let image):
          image.resizable().scaledToFit()
        case .failure:
          ZStack {
            Color.yellow.opacity(0.3)
            Text("Image could not be loaded.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }

    case .customURLSession:
      RemoteImage(
        url: .cuteDoggo,
        urlSession: .shared,
        configuration: RemoteImageConfiguration(
          skipCache: true,
          transaction: Transaction(
            animation: .easeInOut(duration: 0.5))))
      {
        $0.resizable().scaledToFit()
      }

    case .customCache:
      RemoteImage(url: .cuteDoggo, cache: .shared) { image in
        image.resizable().scaledToFit()
      }
    }
  }
}

extension URL {
  fileprivate static let cuteDoggo = URL(string: "https://fastly.picsum.photos/id/237/1000/1000.jpg?hmac=5nME13-xBzl4yi2t1tFev6zsf5IWO2-efZAoXEm9ltc")!

  fileprivate static let githubRepo = URL(string: "https://github.com/bdbergeron/RemoteImage")!
}

#if DEBUG
// MARK: - DemosListPreviews

struct DemosListPreviews: PreviewProvider {
  static var previews: some View {
    DemosList()
  }
}
#endif
