//
//  OnboardingProgressionView.swift
//  Unit
//
//  Screen 7 — Default weekly increment.
//  Global only — per-exercise overrides live in CycleSettingsView post-launch.
//

import SwiftUI

struct OnboardingProgressionView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var onContinue: () -> Void

    var body: some View {
        OnboardingShell(
            title: "How much weight do you add per week?",
            ctaLabel: "Continue",
            onContinue: onContinue
        ) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.lg) {

                // Description
                Text("When you hit your target, Unit adds:")
                    .font(AtlasTheme.Typography.body)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)

                // Increment selector
                HStack {
                    Button {
                        vm.stepDown()
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AtlasTheme.Colors.textPrimary)
                            .frame(width: 48, height: 48)
                            .background(AtlasTheme.Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
                    }

                    Spacer()

                    Text(vm.incrementDisplayLabel())
                        .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(AtlasTheme.Colors.textPrimary)

                    Spacer()

                    Button {
                        vm.stepUp()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AtlasTheme.Colors.textPrimary)
                            .frame(width: 48, height: 48)
                            .background(AtlasTheme.Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
                    }
                }
                .padding(AtlasTheme.Spacing.md)
                .background(AtlasTheme.Colors.elevatedBackground)
                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))

                // Guidance
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                    GuidanceRow(label: "Most lifters", value: "2.5 \(vm.weightUnitLabel)")
                    GuidanceRow(label: "Upper body compounds", value: "2.5 \(vm.weightUnitLabel)")
                    GuidanceRow(label: "Lower body compounds", value: "5 \(vm.weightUnitLabel)")
                    GuidanceRow(label: "Accessories / isolation", value: "1.25–2.5 \(vm.weightUnitLabel)")
                }
                .padding(AtlasTheme.Spacing.md)
                .background(AtlasTheme.Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))

                Text("You can override this per-exercise in settings after your first session.")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
            }
        }
    }
}

private struct GuidanceRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AtlasTheme.Typography.caption)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(AtlasTheme.Colors.textPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingProgressionView { }
            .environment(OnboardingViewModel())
            .preferredColorScheme(.dark)
    }
    .tint(AtlasTheme.Colors.accent)
}
