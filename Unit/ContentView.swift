//
//  ContentView.swift
//  Unit
//
//  Root: Tab navigation (Home, Program, Settings).
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: RootTab = .home

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainTabView
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            configureNavigationBarAppearance()
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label(RootTab.home.title, systemImage: RootTab.home.systemImage)
                }
                .tag(RootTab.home)

            TemplatesView()
                .tabItem {
                    Label(RootTab.program.title, systemImage: RootTab.program.systemImage)
                }
                .tag(RootTab.program)

            SettingsView(showsCloseButton: false)
                .tabItem {
                    Label(RootTab.settings.title, systemImage: RootTab.settings.systemImage)
                }
                .tag(RootTab.settings)
        }
        .tint(.black)
        .onAppear(perform: configureTabBarAppearance)
        .environment(\.appTabSelection, AppTabSelection { tab in
            selectedTab = tab
        })
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.shadowColor = UIColor(white: 0, alpha: 0.08)

        let selectedColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        let unselectedColor = UIColor(red: 0.557, green: 0.557, blue: 0.557, alpha: 1)

        [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance]
            .forEach { itemAppearance in
                itemAppearance.selected.iconColor = selectedColor
                itemAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
                itemAppearance.normal.iconColor = unselectedColor
                itemAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedColor]
            }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.shadowColor = .clear

        let titleColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.tintColor = titleColor
    }
}

struct AppTabSelection {
    let select: (RootTab) -> Void

    func callAsFunction(_ tab: RootTab) {
        select(tab)
    }
}

private struct AppTabSelectionKey: EnvironmentKey {
    static let defaultValue = AppTabSelection { _ in }
}

extension EnvironmentValues {
    var appTabSelection: AppTabSelection {
        get { self[AppTabSelectionKey.self] }
        set { self[AppTabSelectionKey.self] = newValue }
    }
}

enum RootTab: Hashable {
    case home
    case program
    case settings

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .program:
            return "Program"
        case .settings:
            return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return AppIcon.home.systemName
        case .program:
            return AppIcon.program.systemName
        case .settings:
            return AppIcon.settings.systemName
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.makePreviewContainer())

}
