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

            VStack(spacing: AppTheme.spacing.lg) {
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
            .padding(.horizontal, AppTheme.spacing.lg)
            .padding(.bottom, AppTheme.spacing.xl)
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
        .padding(.top, AppTheme.spacing.sm)
    }

    private var pageIndicator: some View {
        HStack(spacing: AppTheme.spacing.sm) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == selection ? AppTheme.colors.text : AppTheme.colors.secondaryText.opacity(0.3))
                    .frame(width: index == selection ? 22 : 8, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: selection)
            }
        }
        .padding(.top, AppTheme.spacing.sm)
    }

    private var stepLabel: some View {
        Text("Step \(selection + 1) of \(pages.count)")
            .font(AppTheme.fonts.captionSemibold)
            .foregroundStyle(AppTheme.colors.secondaryText)
    }

    private var actionArea: some View {
        VStack(spacing: AppTheme.spacing.sm) {
            Group {
                if selection == 2 {
                    Button("Not Now") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        goForward()
                    }
                    .font(AppTheme.fonts.subheadlineSemibold)
                    .foregroundStyle(AppTheme.colors.secondaryText)
                } else {
                    Text("Not Now")
                        .font(AppTheme.fonts.subheadlineSemibold)
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
        VStack(spacing: AppTheme.spacing.lg) {
            hero
                .frame(height: 240)

            VStack(spacing: AppTheme.spacing.sm) {
                Text(page.title)
                    .font(AppTheme.fonts.largeTitleSemibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.colors.text)

                Text(page.subtitle)
                    .font(AppTheme.fonts.body)
                    .foregroundStyle(AppTheme.colors.secondaryText)
                    .multilineTextAlignment(.center)
                if index == 2 {
                    Text("We only use notifications for your tasks.")
                        .font(AppTheme.fonts.caption)
                        .foregroundStyle(AppTheme.colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .opacity(isActive ? 1 : 0)
            .scaleEffect(isActive ? 1 : 0.96)
            .animation(.easeInOut(duration: 0.32), value: isActive)
        }
        .padding(.top, AppTheme.spacing.md)
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
                        .stroke(AppTheme.colors.text.opacity(0.15), lineWidth: 1)
                )
                .frame(width: 280, height: 170)
                .overlay(cardContent)
                .matchedGeometryEffect(id: "hero.card", in: namespace)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
            HStack(spacing: AppTheme.spacing.sm) {
                Image(systemName: page.symbol)
                    .font(.title2)
                    .foregroundStyle(LinearGradient(colors: page.accent, startPoint: .topLeading, endPoint: .bottomTrailing))

                Text("TaskFlow")
                    .font(AppTheme.fonts.headlineSemibold)
                    .foregroundStyle(AppTheme.colors.text)

                Spacer()
            }

            if index == 1 {
                HStack(spacing: AppTheme.spacing.xs) {
                    pill("Today")
                    pill("Upcoming")
                    pill("Later")
                }
                HStack(spacing: AppTheme.spacing.sm) {
                    Capsule()
                        .fill(AppTheme.colors.secondaryText.opacity(0.15))
                        .frame(height: 12)
                    Circle()
                        .fill(AppTheme.colors.primary)
                        .frame(width: 8, height: 8)
                }
                Text("Plan the week")
                    .font(AppTheme.fonts.subheadlineSemibold)
                    .foregroundStyle(AppTheme.colors.text)
            } else if index == 2 {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(AppTheme.colors.primary)
                    Text("Reminder at 5:00 PM")
                        .font(AppTheme.fonts.subheadline)
                        .foregroundStyle(AppTheme.colors.text)
                }
            } else if index == 3 {
                Text("Your day, clarified.")
                    .font(AppTheme.fonts.subheadlineSemibold)
                    .foregroundStyle(AppTheme.colors.text)
            } else {
                Text("Keep your focus gentle and steady.")
                    .font(AppTheme.fonts.subheadline)
                    .foregroundStyle(AppTheme.colors.secondaryText)
            }

            Spacer()
        }
        .padding(AppTheme.spacing.md)
    }

    private func pill(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.fonts.captionSemibold)
            .foregroundStyle(AppTheme.colors.text)
            .padding(.horizontal, AppTheme.spacing.sm)
            .padding(.vertical, AppTheme.spacing.xxs)
            .background(
                Capsule()
                    .fill(AppTheme.colors.secondaryBackground)
            )
    }
}

#Preview {
    OnboardingView { _ in }
}
