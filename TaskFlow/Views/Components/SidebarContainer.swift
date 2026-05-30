import SwiftUI

struct SidebarContainer: View {
    @Environment(AppState.self) private var appState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var sidebarWidth: CGFloat {
        horizontalSizeClass == .regular
            ? UIScreen.main.bounds.width * 0.4
            : UIScreen.main.bounds.width * 0.75
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if appState.isSidebarOpen {
                backdrop
                    .transition(.opacity)
                    .zIndex(1)
            }

            if appState.isSidebarOpen {
                SidebarView()
                    .frame(width: sidebarWidth)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: appState.isSidebarOpen)
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if appState.isSidebarOpen && value.translation.width < -threshold {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            appState.isSidebarOpen = false
                        }
                    }
                }
        )
        .ignoresSafeArea()
        .allowsHitTesting(appState.isSidebarOpen)
    }

    private var backdrop: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    appState.isSidebarOpen = false
                }
            }
    }
}
