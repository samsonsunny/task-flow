import SwiftUI
import UIKit

/// Hides or shows the enclosing `UITabBarController`'s tab bar.
///
/// The app's root is a UIKit `UITabBarController`, so SwiftUI's
/// `.toolbar(.hidden, for: .tabBar)` does not apply. This helper adjusts the
/// tab bar directly when a pushed screen should take over the bottom area.
struct TabBarVisibilityAdjuster: UIViewControllerRepresentable {
    let hidden: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = AdjusterViewController()
        controller.hidden = hidden
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        (uiViewController as? AdjusterViewController)?.hidden = hidden
    }
}

private final class AdjusterViewController: UIViewController {
    var hidden = false {
        didSet {
            guard hidden != oldValue else { return }
            apply()
        }
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        apply()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        apply()
    }

    private func apply() {
        tabBarController?.setTabBarHidden(hidden, animated: true)
    }
}

private extension UITabBarController {
    func setTabBarHidden(_ hidden: Bool, animated: Bool) {
        guard tabBar.isHidden != hidden else { return }

        let originalFrame = tabBar.frame
        let offset = originalFrame.height
        let duration = animated ? 0.28 : 0

        if hidden {
            tabBar.isHidden = false
            UIView.animate(withDuration: duration, animations: {
                self.tabBar.frame = originalFrame.offsetBy(dx: 0, dy: offset)
            }, completion: { _ in
                self.tabBar.isHidden = true
                self.tabBar.frame = originalFrame
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            })
        } else {
            tabBar.isHidden = false
            tabBar.frame = originalFrame.offsetBy(dx: 0, dy: offset)
            UIView.animate(withDuration: duration, animations: {
                self.tabBar.frame = originalFrame
            }, completion: { _ in
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            })
        }
    }
}
