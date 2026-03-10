//
//  OnboardingPathView.swift
//  Unit
//
//  Screen 2 — Setup path selection.
//  Build my cycle (full flow) vs Try a sample cycle (condensed).
//

import SwiftUI

struct OnboardingPathView: View {
    var onSelect: (OnboardingViewModel.SetupPath) -> Void

    var body: some View {
        OnboardingShell(title: "How do you want to start?") {
            VStack(spacing: AtlasTheme.Spacing.sm) {
                PathCard(
                    icon: "slider.horizontal.3",
                    title: "Build my cycle",
                    subtitle: "I have a program — I'll enter it now."
                ) {
                    onSelect(.build)
                }

                PathCard(
                    icon: "bolt.fill",
                    title: "Try a sample cycle",
                    subtitle: "See how Unit works with a pre-built Push / Pull / Legs program."
                ) {
                    onSelect(.sample)
                }
            }
        }
    }
}

// MARK: - PathCard

private struct PathCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AtlasTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AtlasTheme.Colors.accent)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AtlasTheme.Typography.sectionTitle)
                        .foregroundStyle(AtlasTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
            }
            .padding(AtlasTheme.Spacing.md)
            .background(AtlasTheme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        OnboardingPathView { _ in }
            .preferredColorScheme(.dark)
    }
    .tint(AtlasTheme.Colors.accent)
}
