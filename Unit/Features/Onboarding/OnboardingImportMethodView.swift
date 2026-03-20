//
//  OnboardingImportMethodView.swift
//  Unit
//
//  Screen 3 — Choose how to bring an existing program into onboarding.
//

import SwiftUI

struct OnboardingImportMethodView: View {
    var progressStep: Int
    var progressTotal: Int
    var onSelect: (OnboardingViewModel.ImportMethod) -> Void

    var body: some View {
        OnboardingShell(
            title: "How do you want to add your program?",
            progressStep: progressStep,
            progressTotal: progressTotal
        ) {
            VStack(spacing: AppSpacing.sm) {
                ImportMethodCard(
                    icon: .camera,
                    title: "Take a photo",
                    subtitle: "Capture your current sheet and let Unit pull out the exercises, sets, reps, and weights."
                ) {
                    onSelect(.photo)
                }

                ImportMethodCard(
                    icon: .clipboard,
                    title: "Paste text",
                    subtitle: "Copy your program from notes or a message and let Unit structure it for you."
                ) {
                    onSelect(.paste)
                }

                ImportMethodCard(
                    icon: .keyboard,
                    title: "Enter manually",
                    subtitle: "Type in each training day and exercise yourself."
                ) {
                    onSelect(.manual)
                }
            }
        }
    }
}

private struct ImportMethodCard: View {
    let icon: AppIcon
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                icon.image(size: 18, weight: .semibold)
                    .foregroundStyle(AppColor.accent)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFont.sectionHeader.font)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(subtitle)
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.md)
            .background(AppColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        OnboardingImportMethodView(progressStep: 2, progressTotal: 7) { _ in }
    }
}
