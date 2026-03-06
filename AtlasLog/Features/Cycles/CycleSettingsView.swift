//
//  CycleSettingsView.swift
//  AtlasLog
//
//  Settings sheet for an active cycle: increment, auto-deload, name, danger zone.
//

import SwiftUI
import SwiftData

struct CycleSettingsView: View {
    @Bindable var cycle: Cycle

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var rules: [ProgressionRule]
    @State private var showingResetConfirm = false

    private var cycleRules: [ProgressionRule] {
        rules.filter { $0.cycleId == cycle.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cycle Name") {
                    TextField("Name", text: $cycle.name)
                        .frame(minHeight: 44)
                }

                Section("Defaults") {
                    Stepper(
                        value: $cycle.globalIncrementKg,
                        in: 0.5...10.0,
                        step: 0.5
                    ) {
                        HStack {
                            Text("Global Increment")
                            Spacer()
                            Text("\(cycle.globalIncrementKg.weightString) kg/week")
                                .foregroundStyle(AtlasTheme.Colors.accent)
                                .monospacedDigit()
                        }
                    }
                    .frame(minHeight: 44)
                }

                Section("Danger Zone") {
                    Button(role: .destructive) {
                        showingResetConfirm = true
                    } label: {
                        Label("Reset Cycle", systemImage: "arrow.counterclockwise.circle")
                            .frame(minHeight: 44)
                    }
                    .confirmationDialog(
                        "Reset Cycle",
                        isPresented: $showingResetConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Reset — Erase All Progress", role: .destructive) {
                            resetCycle()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This resets all failure counts and deload flags. Logged sessions are preserved.")
                    }
                }
            }
            .navigationTitle("Cycle Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }

    private func resetCycle() {
        for rule in cycleRules {
            rule.consecutiveFailures = 0
            rule.isDeloaded = false
        }
        try? modelContext.save()
        dismiss()
    }

}
