//
//  SettingsView.swift
//  Unit
//
//  Settings tab: units, default increment, app info.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("unitSystem") private var unitSystem: String = "kg"
    @AppStorage("defaultIncrementKg") private var defaultIncrementKg: Double = 2.5

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Weight Unit", selection: $unitSystem) {
                        Text("kg").tag("kg")
                        Text("lb").tag("lb")
                    }
                    .pickerStyle(.segmented)
                    .frame(minHeight: 44)
                }

                Section {
                    Stepper(
                        value: $defaultIncrementKg,
                        in: 0.5...10.0,
                        step: 0.5
                    ) {
                        HStack {
                            Text("Default Increment")
                            Spacer()
                            Text("\(defaultIncrementKg.weightString) kg")
                                .foregroundStyle(Theme.Colors.accent)
                                .monospacedDigit()
                        }
                    }
                    .frame(minHeight: 44)
                } header: {
                    Text("Progression")
                } footer: {
                    Text("Applied to new cycles when no per-exercise override is set.")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .frame(minHeight: 44)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
