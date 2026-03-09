//
//  CyclesView.swift
//  Unit
//
//  Minimal cycles screen so app can compile and run.
//

import SwiftUI
import SwiftData

struct CyclesView: View {
    @Query(sort: \Cycle.startDate, order: .reverse) private var cycles: [Cycle]

    private var activeCycle: Cycle? {
        cycles.first(where: { $0.isActive && !$0.isCompleted })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                    if let cycle = activeCycle {
                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                            Text("Active Cycle")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            Text(cycle.name)
                                .font(AtlasTheme.Typography.sectionTitle)
                            Text("Week \(cycle.currentWeekNumber) of \(cycle.weekCount)")
                                .font(AtlasTheme.Typography.body)
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        }
                        .atlasCardStyle()
                    } else {
                        Text("No active cycle")
                            .font(AtlasTheme.Typography.sectionTitle)
                            .atlasCardStyle()
                    }
                }
                .padding(AtlasTheme.Spacing.md)
            }
            .background(AtlasTheme.Colors.background)
            .navigationTitle("Cycles")
        }
    }
}

#Preview {
    CyclesView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
        .preferredColorScheme(.dark)
}
