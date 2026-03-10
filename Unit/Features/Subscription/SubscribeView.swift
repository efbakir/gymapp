//
//  SubscribeView.swift
//  Unit
//
//  Paywall: Atlas Log Pro with limited free tier option.
//

import SwiftUI

struct SubscribeView: View {
    @AppStorage("isPremium") private var isPremium = false
    @Environment(\.dismiss) private var dismiss

    private let features: [(icon: String, title: String, subtitle: String)] = [
        ("arrow.up.right.circle.fill", "Auto-Progression", "8-week cycles that add weight automatically based on your performance"),
        ("target", "Target Tracking", "See exactly what weight and reps to hit each session"),
        ("chart.line.uptrend.xyaxis", "Progress Charts", "Visualise strength trends and PR history across exercises")
    ]

    var body: some View {
        ZStack {
            AtlasTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Hero
                    heroSection
                        .padding(.top, AtlasTheme.Spacing.xl)

                    // Features
                    VStack(spacing: AtlasTheme.Spacing.sm) {
                        ForEach(features, id: \.title) { feature in
                            featureRow(feature)
                        }
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.md)
                    .padding(.top, AtlasTheme.Spacing.xl)

                    // Free tier note
                    Text("Free tier: log workouts manually. No cycles, no targets, no charts.")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AtlasTheme.Spacing.xl)
                        .padding(.top, AtlasTheme.Spacing.lg)

                    // CTAs
                    VStack(spacing: AtlasTheme.Spacing.sm) {
                        Button {
                            isPremium = true
                            dismiss()
                        } label: {
                            Text("Start Free Trial — 7 Days")
                                .atlasCTAStyle()
                        }
                        .buttonStyle(.plain)

                        Button {
                            dismiss()
                        } label: {
                            Text("Continue for free")
                                .font(AtlasTheme.Typography.body)
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                                .frame(height: 44)
                        }
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.md)
                    .padding(.top, AtlasTheme.Spacing.lg)
                    .padding(.bottom, AtlasTheme.Spacing.xxl)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var heroSection: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(AtlasTheme.Colors.accentSoft)
                    .frame(width: 80, height: 80)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(AtlasTheme.Colors.accent)
            }

            VStack(spacing: AtlasTheme.Spacing.xs) {
                Text("Atlas Log Pro")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(AtlasTheme.Colors.textPrimary)

                Text("Train smarter with auto-progression")
                    .font(AtlasTheme.Typography.body)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, AtlasTheme.Spacing.xl)
    }

    private func featureRow(_ feature: (icon: String, title: String, subtitle: String)) -> some View {
        HStack(alignment: .top, spacing: AtlasTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AtlasTheme.Radius.sm, style: .continuous)
                    .fill(AtlasTheme.Colors.accentSoft)
                    .frame(width: 40, height: 40)
                Image(systemName: feature.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AtlasTheme.Colors.accent)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(AtlasTheme.Typography.sectionTitle)
                    .foregroundStyle(AtlasTheme.Colors.textPrimary)
                Text(feature.subtitle)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AtlasTheme.Spacing.md)
        .background(AtlasTheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))
    }
}

#Preview {
    SubscribeView()
        .preferredColorScheme(.dark)
}
