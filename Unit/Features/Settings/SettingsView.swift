//
//  SettingsView.swift
//  Unit
//
//  Settings tab: units, default increment, app info.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("unitSystem") private var unitSystem: String = "kg"

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
                .listRowBackground(AtlasTheme.Colors.elevatedBackground)

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    }
                    .frame(minHeight: 44)
                }
                .listRowBackground(AtlasTheme.Colors.elevatedBackground)
            }
            .scrollContentBackground(.hidden)
            .background(AtlasTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
