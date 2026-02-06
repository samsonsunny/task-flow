//
//  OnboardingView.swift
//  TaskFlow
//
//  Created by AI on 06-02-2026.
//

import SwiftUI
import UIKit

struct OnboardingView: View {
    @State private var selection = 0
    @State private var isRequestingNotifications = false
    @AppStorage("taskflow.notifications.enabled") private var notificationsEnabled = false
    @AppStorage("taskflow.notifications.denied") private var notificationsDenied = false
    @AppStorage("dailyReviewEnabled") private var dailyReviewEnabled = true
    @Namespace private var heroNamespace
    @State private var lastSelection = 0

    let onComplete: (Bool) -> Void

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to TaskFlow",
            subtitle: "A calm place to plan what matters.",
            symbol: "checkmark.circle.fill",
            accent: [Color.blue, Color.cyan]
        ),
        OnboardingPage(
            title: "Plan and capture fast",
            subtitle: "Three horizons and instant add keep you moving.",
            symbol: "rectangle.3.group.fill",
            accent: [Color.teal, Color.green]
        ),
        OnboardingPage(
            title: "Stay on track",
            subtitle: "Enable reminders for gentle due-date nudges.",
            symbol: "bell.badge.fill",
            accent: [Color.indigo, Color.blue]
        ),
        OnboardingPage(
            title: "You're all set",
            subtitle: "Create your first task to begin.",
            symbol: "sparkles",
            accent: [Color.purple, Color.pink]
        )
    ]

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                header

                Spacer()

                TabView(selection: $selection) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(
                            page: pages[index],
                            index: index,
                            namespace: heroNamespace,
                            isActive: index == selection
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: selection) { _, newValue in
                    if newValue != lastSelection {
                        lastSelection = newValue
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }
                }

                pageIndicator
                stepLabel
                Spacer()

                actionArea
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(UIColor.systemBackground),
                Color(UIColor.secondarySystemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RadialGradient(
                colors: [
                    pages[selection].accent.first?.opacity(0.18) ?? .clear,
                    .clear
                ],
                center: .topLeading,
                startRadius: 40,
                endRadius: 320
            )
        )
    }

    private var header: some View {
        HStack {
            Spacer()
        }
        .padding(.top, AppTheme.Spacing.sm)
    }

    private var pageIndicator: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == selection ? AppTheme.Colors.text : AppTheme.Colors.secondaryText.opacity(0.3))
                    .frame(width: index == selection ? 22 : 8, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: selection)
            }
        }
        .padding(.top, AppTheme.Spacing.sm)
    }

    private var stepLabel: some View {
        Text("Step \(selection + 1) of \(pages.count)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.Colors.secondaryText)
    }

    private var actionArea: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Group {
                if selection == 2 {
                    Button("Not Now") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        goForward()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                } else {
                    Text("Not Now")
                        .font(.subheadline.weight(.semibold))
                        .opacity(0)
                }
            }
            .frame(height: 20)

            Button {
                if selection == 2 {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    requestNotifications {
                        goForward()
                    }
                } else if selection == pages.count - 1 {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onComplete(true)
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    goForward()
                }
            } label: {
                Text(selection == pages.count - 1 ? "Start Planning" : (selection == 2 ? (isRequestingNotifications ? "Enabling..." : "Enable Reminders") : "Continue"))
                    .frame(maxWidth: .infinity, minHeight: 54)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selection == 2 && isRequestingNotifications)
        }
    }

    private func goForward() {
        withAnimation(.easeInOut) {
            selection = min(selection + 1, pages.count - 1)
        }
    }

    private func requestNotifications(completion: @escaping () -> Void) {
        isRequestingNotifications = true
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            await MainActor.run {
                notificationsEnabled = granted
                notificationsDenied = !granted
                if granted {
                    dailyReviewEnabled = true
                }
                isRequestingNotifications = false
                completion()
            }
        }
    }

}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let accent: [Color]
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let index: Int
    let namespace: Namespace.ID
    let isActive: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            hero
                .frame(height: 240)

            VStack(spacing: AppTheme.Spacing.sm) {
                Text(page.title)
                    .font(.largeTitle.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.Colors.text)

                Text(page.subtitle)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                if index == 2 {
                    Text("We only use notifications for your tasks.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .opacity(isActive ? 1 : 0)
            .scaleEffect(isActive ? 1 : 0.96)
            .animation(.easeInOut(duration: 0.32), value: isActive)
        }
        .padding(.top, AppTheme.Spacing.md)
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(LinearGradient(colors: page.accent, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 260, height: 180)
                .opacity(0.18)
                .blur(radius: 28)
                .offset(x: 20, y: 30)

            Circle()
                .fill(LinearGradient(colors: page.accent, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 190, height: 190)
                .offset(x: -40, y: -30)
                .matchedGeometryEffect(id: "hero.circle.primary", in: namespace)

            Circle()
                .stroke(page.accent.first?.opacity(0.4) ?? .clear, lineWidth: 2)
                .frame(width: 160, height: 160)
                .offset(x: 70, y: 20)
                .matchedGeometryEffect(id: "hero.circle.secondary", in: namespace)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .frame(width: 280, height: 170)
                .overlay(cardContent)
                .matchedGeometryEffect(id: "hero.card", in: namespace)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: page.symbol)
                    .font(.title2)
                    .foregroundStyle(LinearGradient(colors: page.accent, startPoint: .topLeading, endPoint: .bottomTrailing))

                Text("TaskFlow")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.text)

                Spacer()
            }

            if index == 1 {
                HStack(spacing: AppTheme.Spacing.xs) {
                    pill("Today")
                    pill("Upcoming")
                    pill("Later")
                }
                HStack(spacing: AppTheme.Spacing.sm) {
                    Capsule()
                        .fill(AppTheme.Colors.secondaryText.opacity(0.15))
                        .frame(height: 12)
                    Circle()
                        .fill(AppTheme.Colors.primary)
                        .frame(width: 8, height: 8)
                }
                Text("Plan the week")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.text)
            } else if index == 2 {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(AppTheme.Colors.primary)
                    Text("Reminder at 5:00 PM")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.text)
                }
            } else if index == 3 {
                Text("Your day, clarified.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.text)
            } else {
                Text("Keep your focus gentle and steady.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
    }

    private func pill(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.Colors.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(AppTheme.Colors.secondaryBackground)
            )
    }
}

#Preview {
    OnboardingView { _ in }
}
