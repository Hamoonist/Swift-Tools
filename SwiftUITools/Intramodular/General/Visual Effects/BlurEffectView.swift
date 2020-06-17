//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)

import Swift
import SwiftUI
import UIKit

public struct BlurEffectView<Content: View>: View {
    private let content: Content
    private let style: UIBlurEffect.Style
    
    public init(style: UIBlurEffect.Style, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.style = style
    }
    
    public var body: some View {
        VisualEffectView(effect: UIBlurEffect(style: style)) {
            content
        }
    }
}

#endif
