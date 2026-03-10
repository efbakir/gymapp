 //
//  ContentView.swift
//  Unit
//
//  Root: Tab navigation (Home, Program, Settings).
//

import SwiftUI
import SwiftData
import UIKit

private func atlasDynamicColor(light: UInt32, dark: UInt32, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) -> Color {
    Color(
        uiColor: UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(hex: dark, alpha: darkAlpha)
            } else {
                return UIColor(hex: light, alpha: lightAlpha)
            }
        }
    )
}

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("forceLightMode") private var forceLightMode = false
    @State private var selectedTab: RootTab = .home

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainTabView
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(forceLightMode ? .light : .dark)
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

            SettingsView()
                .tabItem {
                    Label(RootTab.settings.title, systemImage: RootTab.settings.systemImage)
                }
                .tag(RootTab.settings)
        }
        .tint(AtlasTheme.Colors.secondaryButton)
        .onAppear(perform: configureTabBarAppearance)
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(hex: 0x181C22, alpha: 0.98)
            } else {
                return UIColor(hex: 0xF7F7F8, alpha: 0.98)
            }
        }
        appearance.shadowColor = .clear

        let selectedColor = UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(hex: 0xF5F7FA)
            } else {
                return UIColor(hex: 0x17191C)
            }
        }
        let unselectedColor = UIColor(hex: 0x484B51)

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
}

private enum RootTab: Hashable {
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
            return "house.fill"
        case .program:
            return "square.grid.2x2.fill"
        case .settings:
            return "gearshape.fill"
        }
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
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 12
    }

    enum Colors {
        static let accent = atlasDynamicColor(light: 0xFF5500, dark: 0xFF5500)
        static let accentSoft = atlasDynamicColor(light: 0xFF5500, dark: 0xFF5500, lightAlpha: 0.12, darkAlpha: 0.16)

        static let secondaryButton = atlasDynamicColor(light: 0x484B51, dark: 0x484B51)
        static let successAccent = atlasDynamicColor(light: 0x1F9D55, dark: 0x22C55E)

        static let background = atlasDynamicColor(light: 0xEBEBEB, dark: 0x101214)
        static let elevatedBackground = atlasDynamicColor(light: 0xF4F4F5, dark: 0x181B20)
        static let card = atlasDynamicColor(light: 0xFAFAFA, dark: 0x20242A)
        static let sheet = atlasDynamicColor(light: 0xFAFAFA, dark: 0x262B33)
        static let tabBarBackground = atlasDynamicColor(light: 0xF7F7F8, dark: 0x181C22, lightAlpha: 0.98, darkAlpha: 0.94)
        static let tabSelectedBackground = atlasDynamicColor(light: 0xECECEE, dark: 0x2A3039)

        static let textPrimary = atlasDynamicColor(light: 0x17191C, dark: 0xF5F7FA)
        static let textSecondary = atlasDynamicColor(light: 0x6A7078, dark: 0x9AA1AA)
        static let tabItemInactive = atlasDynamicColor(light: 0x484B51, dark: 0x8C949F)
        static let disabled = atlasDynamicColor(light: 0xC9CDD2, dark: 0x3A414B)

        static let border = atlasDynamicColor(light: 0xD5D8DD, dark: 0x343A44)
        static let shadow = atlasDynamicColor(light: 0x111111, dark: 0x000000, lightAlpha: 0.08, darkAlpha: 0.34)

        static let progress = atlasDynamicColor(light: 0xE56A1E, dark: 0xFF7A29)

        static let failureAccent = atlasDynamicColor(light: 0xD64545, dark: 0xFF6B6B)
        static let deloadBadge = atlasDynamicColor(light: 0xC96A19, dark: 0xF59E0B)
    }

    enum Typography {
        static let hero = Font.system(.title2, design: .rounded).weight(.bold)
        static let sectionTitle = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let metric = Font.system(.title3, design: .rounded).weight(.semibold)
        /// Large monospaced numerics — workout input fields and weight/reps display
        static let numericDisplay = Font.system(size: 36, weight: .bold, design: .rounded).monospacedDigit()
        /// Overline label above data — render ALL CAPS at call site, use with `.tracking(1.0)`
        static let overline = Font.system(size: 10, weight: .semibold, design: .rounded)
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

    /// Primary CTA button style: gradient fill + orange glow.
    /// Apply to the button label content (Text or Label).
    func atlasCTAStyle() -> some View {
        self
            .font(AtlasTheme.Typography.sectionTitle.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AtlasTheme.Colors.accent)
            .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))
    }
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255
        let green = CGFloat((hex & 0x00FF00) >> 8) / 255
        let blue = CGFloat(hex & 0x0000FF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
}
