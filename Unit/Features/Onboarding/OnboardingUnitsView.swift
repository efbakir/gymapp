//
//  OnboardingUnitsView.swift
//  Unit
//
//  Screen 3 — Unit selection: kg or lb.
//

import SwiftUI

struct OnboardingUnitsView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var onContinue: () -> Void

    var body: some View {
        OnboardingShell(
            title: "What unit do you use?",
            ctaLabel: "Continue",
            onContinue: onContinue
        ) {
            @Bindable var vm = vm

            VStack(spacing: AppSpacing.xl) {
                Picker("Weight Unit", selection: $vm.unitSystem) {
                    Text("kg").tag("kg")
                    Text("lb").tag("lb")
                }
                .pickerStyle(.segmented)
                .tint(AppColor.accent)
            }
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingUnitsView { }
            .environment(OnboardingViewModel())
    }
    .tint(AppColor.accent)
}
