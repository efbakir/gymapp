//
//  ContentView.swift
//  AtlasLog
//
//  Root: Tab navigation (Home, Program, History).
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            TemplatesView()
                .tabItem {
                    Label("Program", systemImage: "list.bullet.rectangle")
                }
                .tag(1)
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
        }
        .tint(AtlasTheme.Colors.accent)
    }
}

enum AtlasTheme {
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
    }

    enum Shadow {
        static let card = Color.black.opacity(0.06)
    }

    enum Colors {
        static let accent = Color(red: 1.0, green: 0.27, blue: 0.0)
        static let accentSoft = Color(red: 1.0, green: 0.27, blue: 0.0).opacity(0.12)
        static let background = Color(.systemGroupedBackground)
        static let card = Color(.systemBackground)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let border = Color.black.opacity(0.08)
        static let progress = Color(red: 0.84, green: 0.33, blue: 0.0)
    }

    enum Typography {
        static let hero = Font.system(.title2, design: .rounded).weight(.bold)
        static let sectionTitle = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let metric = Font.system(.title3, design: .rounded).weight(.semibold)
    }
}

extension View {
    func atlasCardStyle() -> some View {
        self
            .padding(AtlasTheme.Spacing.md)
            .background(AtlasTheme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous)
                    .stroke(AtlasTheme.Colors.border, lineWidth: 1)
            )
            .shadow(color: AtlasTheme.Shadow.card, radius: 14, x: 0, y: 8)
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
}
