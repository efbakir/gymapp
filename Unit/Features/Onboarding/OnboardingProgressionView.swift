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
    var progressStep: Int
    var progressTotal: Int
    var onContinue: () -> Void

    var body: some View {
        OnboardingShell(
            title: "How much weight do you add per week?",
            ctaLabel: "Continue",
            progressStep: progressStep,
            progressTotal: progressTotal,
            onContinue: onContinue
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {

                Text("Set one default for compound lifts and one for isolation work.")
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textSecondary)

                VStack(spacing: AppSpacing.sm) {
                    IncrementSelectorRow(
                        title: "Compound exercises",
                        subtitle: "Bench, squat, row, overhead press",
                        value: vm.incrementDisplayLabel(for: .compound),
                        onDecrease: { vm.stepDown(.compound) },
                        onIncrease: { vm.stepUp(.compound) }
                    )

                    IncrementSelectorRow(
                        title: "Isolation exercises",
                        subtitle: "Curls, raises, pushdowns, extensions",
                        value: vm.incrementDisplayLabel(for: .isolation),
                        onDecrease: { vm.stepDown(.isolation) },
                        onIncrease: { vm.stepUp(.isolation) }
                    )
                }
                .padding(AppSpacing.md)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    GuidanceRow(label: "Compound default", value: "2.5–5 \(vm.weightUnitLabel)")
                    GuidanceRow(label: "Isolation default", value: "0–2.5 \(vm.weightUnitLabel)")
                }
                .padding(AppSpacing.md)
                .background(AppColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

                Text("Isolation can stay at 0 if you don't want automatic jumps there.")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }
}

private struct IncrementSelectorRow: View {
    let title: String
    let subtitle: String
    let value: String
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)
                Text(subtitle)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
            }

            HStack {
                Button(action: onDecrease) {
                    AppIcon.remove.image(size: 16, weight: .semibold)
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(AppColor.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                }

                Spacer()

                Text(value)
                    .font(AppFont.numericLarge)
                    .foregroundStyle(AppColor.textPrimary)

                Spacer()

                Button(action: onIncrease) {
                    AppIcon.add.image(size: 16, weight: .semibold)
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(AppColor.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                }
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
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text(value)
                .font(AppFont.captionBold.font)
                .foregroundStyle(AppColor.textPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingProgressionView(progressStep: 5, progressTotal: 6) { }
            .environment(OnboardingViewModel())
    }
    .tint(AppColor.accent)
}
