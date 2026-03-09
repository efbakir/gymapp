//
//  ContentView.swift
//  Unit
//
//  Root: Tab navigation (Home, Program, Cycles, History).
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            HistoryView()
                .tabItem { Label("History", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(1)
            TemplatesView()
                .tabItem { Label("Program", systemImage: "list.bullet.rectangle") }
                .tag(2)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(AtlasTheme.Colors.accent)
        .preferredColorScheme(.dark)
    }
}

// MARK: - AtlasTheme

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

    enum Colors {
        /// Brand accent: orange #FF4400 — restrained; one primary CTA per screen only
        static let accent = Color(red: 1.0, green: 0.267, blue: 0.0)
        static let accentSoft = Color(red: 1.0, green: 0.267, blue: 0.0).opacity(0.12)

        // Dark surfaces — softened near-black with subtle blue-grey tone (not pure black)
        /// Page background: #111318
        static let background = Color(red: 0.067, green: 0.075, blue: 0.094)
        /// Elevated context (grouped sections, sheets): #1A1D25
        static let elevatedBackground = Color(red: 0.102, green: 0.114, blue: 0.145)
        /// Card surface — fills contrast background without shadows: #252831
        static let card = Color(red: 0.145, green: 0.157, blue: 0.192)

        /// Fixed for dark-only UI — does not depend on ColorScheme resolution
        static let textPrimary = Color(white: 0.92)
        static let textSecondary = Color(white: 0.55)

        /// Separator for input field borders (sparse use only)
        static let border = Color(white: 1.0, opacity: 0.12)

        /// Ghost / target text: read-only engine values
        static let ghostText = Color(white: 0.55)

        /// Progress / PR accent: slightly darker orange for dense chart contexts
        static let progress = Color(red: 0.84, green: 0.33, blue: 0.0)

        /// Failure state
        static let failureAccent = Color.red

        /// Deload badge
        static let deloadBadge = Color.orange.opacity(0.8)
    }

    enum Typography {
        static let hero = Font.system(.title2, design: .rounded).weight(.bold)
        static let sectionTitle = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let metric = Font.system(.title3, design: .rounded).weight(.semibold)
    }
}

// MARK: - Double Formatting

extension Double {
    /// Format as weight string: whole numbers as integers, fractional as 1 decimal place.
    /// e.g. 100.0 → "100", 92.5 → "92.5"
    var weightString: String {
        self == floor(self) ? "\(Int(self))" : String(format: "%.1f", self)
    }
}

// MARK: - View Extensions

extension View {
    /// Standard card: fill contrast only — no shadow, no border.
    func atlasCardStyle() -> some View {
        self
            .padding(AtlasTheme.Spacing.md)
            .background(AtlasTheme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
}
