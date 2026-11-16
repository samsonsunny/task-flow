import SwiftUI
import UIKit

/// Re-enables the interactive edge-swipe back gesture on screens that hide the
/// system back button to show a custom one.
struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        EnablerViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private final class EnablerViewController: UIViewController {
    private let popDelegate = PopGestureDelegate()

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        enableGesture()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enableGesture()
    }

    private func enableGesture() {
        guard let navigationController,
              let gesture = navigationController.interactivePopGestureRecognizer else { return }
        popDelegate.navigationController = navigationController
        gesture.delegate = popDelegate
        gesture.isEnabled = true
    }
}

private final class PopGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var navigationController: UINavigationController?

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }
}
