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
            AtlasTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Wordmark + tagline
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                    Text("UNIT")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(AtlasTheme.Colors.textPrimary)
                        .tracking(-1)

                    Text("Your program.\nAuto-adjusted every week.")
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .lineSpacing(6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AtlasTheme.Spacing.xl)

                Spacer()

                // CTA
                Button(action: onGetStarted) {
                    Text("Get Started")
                        .font(AtlasTheme.Typography.sectionTitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AtlasTheme.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))
                }
                .padding(.horizontal, AtlasTheme.Spacing.xl)
                .padding(.bottom, AtlasTheme.Spacing.xxxl)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    OnboardingSplashView { }
        .preferredColorScheme(.dark)
}
