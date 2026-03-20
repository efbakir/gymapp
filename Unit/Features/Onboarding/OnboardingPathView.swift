//
//  OnboardingPathView.swift
//  Unit
//
//  Screen 2 — Setup path selection.
//  Single entry point into the full setup flow.
//

import SwiftUI

struct OnboardingPathView: View {
    var progressStep: Int
    var progressTotal: Int
    var onContinue: () -> Void

    var body: some View {
        OnboardingShell(
            title: "How do you want to start?",
            progressStep: progressStep,
            progressTotal: progressTotal
        ) {
            VStack(spacing: AppSpacing.sm) {
                PathCard(
                    title: "Build my cycle",
                    subtitle: "I have a program — I'll enter it now."
                ) {
                    onContinue()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - PathCard

private struct PathCard: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)
                Text(subtitle)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.md)
            .background(AppColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        OnboardingPathView(progressStep: 1, progressTotal: 6) { }
    }
    .tint(AppColor.accent)
}
