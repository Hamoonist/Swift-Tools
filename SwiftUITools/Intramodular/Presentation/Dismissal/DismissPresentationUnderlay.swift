//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift
import SwiftUI

#if !os(tvOS)

public struct DismissPresentationUnderlay<Content: View>: View {
    @Environment(\.presentationManager) var presentationManager
    
    public let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        GeometryReader { proxy in
            self.content
        }
        .background(
            ClearFillView().onTapGesture {
                self.presentationManager.dismiss()
            }
        )
    }
}

#endif
