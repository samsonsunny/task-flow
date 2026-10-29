import SwiftUI
import UIKit

/// Locates the `UIScrollView` backing a SwiftUI `ScrollView` so callers can
/// interrupt whatever scroll animation or momentum deceleration is in flight.
///
/// Starting a new `ScrollViewProxy.scrollTo` while a previous animation is
/// still running makes the final position unpredictable. Halting first
/// guarantees the next scroll starts from a stationary offset.
final class ScrollAnimationController {
    private weak var anchorView: UIView?

    var scrollView: UIScrollView? {
        anchorView?.enclosingScrollView
    }

    func attach(to view: UIView) {
        anchorView = view
    }

    func halt() {
        guard let scrollView = anchorView?.enclosingScrollView else { return }

        let isLayerAnimating = scrollView.layer.animationKeys()?.isEmpty == false
        let visibleOffset: CGPoint
        if isLayerAnimating, let presentation = scrollView.layer.presentation() {
            visibleOffset = presentation.bounds.origin
        } else {
            visibleOffset = scrollView.contentOffset
        }

        scrollView.layer.removeAllAnimations()

        if scrollView.isDecelerating {
            scrollView.isScrollEnabled = false
            scrollView.isScrollEnabled = true
        }

        scrollView.setContentOffset(visibleOffset, animated: false)
    }
}

/// Zero-sized helper that hooks a `ScrollAnimationController` up to the
/// `UIScrollView` created by the enclosing SwiftUI `ScrollView`. Place it inside
/// the scroll view's content so the view hierarchy is discoverable.
struct ScrollViewLocator: UIViewRepresentable {
    let controller: ScrollAnimationController

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        controller.attach(to: uiView)
    }
}

private extension UIView {
    var enclosingScrollView: UIScrollView? {
        var current = superview
        while let view = current {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            current = view.superview
        }
        return nil
    }
}
