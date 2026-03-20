//
//  OnboardingShell.swift
//  Unit
//
//  Shared onboarding wrapper built on top of AppScreen.
//  Keeps onboarding on the same atom layer: one screen shell, one nav treatment,
//  one sticky primary CTA, one progress component.
//

import SwiftUI

struct OnboardingShell<Content: View>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    var ctaLabel: String = "Continue"
    var ctaEnabled: Bool = true
    var progressStep: Int? = nil
    var progressTotal: Int? = nil
    var onContinue: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        AppScreen(
            leadingAction: NavAction(icon: .back, action: { dismiss() }),
            primaryButton: onContinue.map { action in
                PrimaryButtonConfig(
                    label: ctaLabel,
                    isEnabled: ctaEnabled,
                    action: action
                )
            }
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                if let progressStep, let progressTotal {
                    OnboardingProgress(step: progressStep, total: progressTotal)
                }

                Text(title)
                    .font(AppFont.largeTitle.font)
                    .foregroundStyle(AppColor.textPrimary)

                content()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct OnboardingProgress: View {
    let step: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("\(step) of \(total)")
                .font(AppFont.muted.font)
                .foregroundStyle(AppFont.muted.color)

            HStack(spacing: 6) {
                ForEach(0..<total, id: \.self) { index in
                    Capsule()
                        .fill(index < step ? AppColor.accent : AppColor.border.opacity(0.8))
                        .frame(width: index == step - 1 ? 20 : 10, height: 6)
                }
            }
        }
    }
}
