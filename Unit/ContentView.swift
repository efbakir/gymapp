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
        .tint(Theme.Colors.accent)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
}
