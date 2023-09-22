// Created by Brad Bergeron on 9/22/23.

import SwiftUI

#if os(iOS)
typealias PlatformNativeImage = UIImage
#elseif os(macOS)
typealias PlatformNativeImage = NSImage
#endif

extension Image {
  init(nativeImage: PlatformNativeImage) {
#if os(iOS)
    self.init(uiImage: nativeImage)
#elseif os(macOS)
    self.init(nsImage: nativeImage)
#endif
  }
}

#if os(macOS)
extension NSImage {
  convenience init?(data: Data, scale _: CGFloat) {
    self.init(data: data)
  }
}
#endif
