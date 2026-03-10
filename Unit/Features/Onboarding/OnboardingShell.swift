//
//  OnboardingShell.swift
//  Unit
//
//  Shared layout wrapper for all onboarding screens.
//  Title at top, scrollable content in middle, sticky CTA at bottom.
//

import SwiftUI

struct OnboardingShell<Content: View>: View {
    let title: String
    var ctaLabel: String = "Continue"
    var ctaEnabled: Bool = true
    var onContinue: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .bottom) {
            AtlasTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.lg) {
                    Text(title)
                        .font(AtlasTheme.Typography.hero)
                        .foregroundStyle(AtlasTheme.Colors.textPrimary)
                        .padding(.top, AtlasTheme.Spacing.lg)

                    content()

                    // Bottom padding so content clears the sticky CTA
                    Color.clear.frame(height: 88)
                }
                .padding(.horizontal, AtlasTheme.Spacing.lg)
            }

            // Sticky CTA
            if let onContinue {
                VStack(spacing: 0) {
                    // Gradient fade behind button
                    LinearGradient(
                        colors: [AtlasTheme.Colors.background.opacity(0), AtlasTheme.Colors.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 24)

                    Button(action: onContinue) {
                        Text(ctaLabel)
                            .font(AtlasTheme.Typography.sectionTitle)
                            .foregroundStyle(ctaEnabled ? .white : AtlasTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(ctaEnabled ? AtlasTheme.Colors.accent : AtlasTheme.Colors.disabled)
                            .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))
                    }
                    .disabled(!ctaEnabled)
                    .padding(.horizontal, AtlasTheme.Spacing.lg)
                    .padding(.bottom, AtlasTheme.Spacing.lg)
                    .background(AtlasTheme.Colors.background)
                }
            }
        }
        .background(AtlasTheme.Colors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
