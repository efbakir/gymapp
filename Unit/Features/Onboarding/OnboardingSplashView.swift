//
//  OnboardingSplashView.swift
//  Unit
//
//  Screen 1 — Value prop splash. No data collected.
//  Copy: "Your program. Auto-adjusted every week."
//

import SwiftUI

struct OnboardingSplashView: View {
    var onGetStarted: () -> Void

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Wordmark + tagline
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("UNIT")
                        .font(AppFont.heroDisplay.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .tracking(-1)

                    Text("Your program.\nAuto-adjusted every week.")
                        .font(AppFont.title.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineSpacing(6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.xl)

                Spacer()

                // CTA
                Button(action: onGetStarted) {
                    Text("Get Started")
                        .font(AppFont.sectionHeader.font)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColor.accent)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    OnboardingSplashView { }
}
