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

    private let features: [(icon: AppIcon, title: String, subtitle: String)] = [
        (.progression, "Auto-Progression", "8-week cycles that add weight automatically based on your performance"),
        (.target, "Target Tracking", "See exactly what weight and reps to hit each session"),
        (.chart, "Progress Charts", "Visualise strength trends and PR history across exercises")
    ]

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Hero
                    heroSection
                        .padding(.top, AppSpacing.xl)

                    // Features
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(features, id: \.title) { feature in
                            featureRow(feature)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.xl)

                    // Free tier note
                    Text("Free tier: log workouts manually. No cycles, no targets, no charts.")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.top, AppSpacing.lg)

                    // CTAs
                    VStack(spacing: AppSpacing.sm) {
                        Button {
                            isPremium = true
                            dismiss()
                        } label: {
                            Text("Start Free Trial — 7 Days")
                                .font(AppFont.label.font)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppColor.accent)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button {
                            dismiss()
                        } label: {
                            Text("Continue for free")
                                .font(AppFont.body.font)
                                .foregroundStyle(AppColor.textSecondary)
                                .frame(height: 44)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var heroSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppColor.accentSoft)
                    .frame(width: 80, height: 80)
                AppIcon.bolt.image(size: 36, weight: .bold)
                    .foregroundStyle(AppColor.accent)
            }

            VStack(spacing: AppSpacing.sm) {
                Text("Atlas Log Pro")
                    .font(AppFont.largeTitle.font)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Train smarter with auto-progression")
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    private func featureRow(_ feature: (icon: AppIcon, title: String, subtitle: String)) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(AppColor.accentSoft)
                    .frame(width: 40, height: 40)
                feature.icon.image(size: 18)
                    .foregroundStyle(AppColor.accent)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)
                Text(feature.subtitle)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }
}

#Preview {
    SubscribeView()
}
