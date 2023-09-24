# 🖼️ RemoteImage
A drop-in alternative to SwiftUI's `AsyncImage`, with support for custom URLSessions, caching, and animated phase changes.

![build-ios](https://github.com/bdbergeron/remoteimage/actions/workflows/build-and-test-ios.yml/badge.svg)
![build-macos](https://github.com/bdbergeron/remoteimage/actions/workflows/build-and-test-macos.yml/badge.svg)
[![codecov](https://codecov.io/gh/bdbergeron/remoteimage/graph/badge.svg?token=1PYkoRXex8)](https://codecov.io/gh/bdbergeron/remoteimage)

## Getting Started

Add `RemoteImage` to your project via Swift Package Manager, and add `import RemoteImage` where you want to use it.

```swift
.package(url: "https://github.com/bdbergeron/RemoteImage", from: "1.0.0"),
```

## Usage

`RemoteImage`'s APIs have been designed to make it super easy to adopt in your app/project. In most cases, it's a simple drop-in replacement for SwiftUI's `AsyncImage`.

Check out the `RemoteImage Demos` app in the Xcode project to see some live exmaples.

![Demos](.github/readme/RemoteImageDemos.gif)

### Simple Configuration

```swift
let imageURL: URL?

/// A simple `RemoteImage` view.
RemoteImage(url: imageURL)

/// A simple `RemoteImage` view with modifier closure.
RemoteImage(url: imageURL) {
  $0.resizable().scaledToFit()
}

/// A `RemoteImage` view with a custom placeholder view.
RemoteImage(url: imageURL) {
  $0.resizable().scaledToFit()
} placeholder: {
  ProgressView()
}

/// A `RemoteImage` view with custom placeholder and failure views.
RemoteImage(url: imageURL) {
  $0.resizable().scaledToFit()
} placeholder: {
  ProgressView()
} failure: { error in
  ZStack {
    Color.yellow.opacity(0.3)
    Text("Image could not be loaded.")
      .font(.caption)
      .foregroundStyle(.secondary)
  }
}
```

### Advanced Configuration

```swift
let imageURL: URL?
let urlSession = URLSession(configuration: .ephemeral)
let imageCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 0)

/// Image loaded with a custom `URLSession` and using a custom phase transition animation.
RemoteImage(
  url: imageURL,
  urlSession: urlSession,
  configuration: RemoteImageConfiguration(
    transaction: Transaction(
      animation: .spring(duration: 1.0).delay(0.5))))
{
  $0.resizable().scaledToFit()
}

/// Image loaded from a custom cache. If the image is not yet cached, a new `URLSession`
/// will be constructed using the `URLSessionConfiguration.default` configuration
/// and the provided cache instance.
RemoteImage(url: imageURL, cache: imageCache) {
  $0.resizable().scaledToFit()
} placeholder: {
  ZStack {
    Color.black.opacity(0.05)
    ProgressView()
  }
}
```
