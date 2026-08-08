import SwiftUI
import UIKit

/// Locates the enclosing `UIScrollView` for a SwiftUI list so view-layer code
/// can cancel an in-progress drag/deceleration before programmatic scrolling.
struct ScrollViewIntrospector: UIViewRepresentable {
    let onScrollView: (UIScrollView?) -> Void

    func makeUIView(context: Context) -> IntrospectionView {
        let view = IntrospectionView()
        view.onScrollView = onScrollView
        return view
    }

    func updateUIView(_ uiView: IntrospectionView, context: Context) {
        uiView.onScrollView = onScrollView
    }

    final class IntrospectionView: UIView {
        var onScrollView: ((UIScrollView?) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            onScrollView?(findScrollView(from: superview))
        }

        private func findScrollView(from view: UIView?) -> UIScrollView? {
            guard let view else { return nil }
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            return findScrollView(from: view.superview)
        }
    }
}
