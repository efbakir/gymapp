//
//  AppScreen.swift
//  Unit
//
//  Five-Tier UI — Layer 4: Template
//  The only page wrapper. Owns AppNavBar, scroll container, horizontal padding,
//  optional sticky AppPrimaryButton, and safe-area behaviour.
//  Screens pass title and actions in; screens do NOT create their own nav, scroll,
//  or bottom CTA layout.
//

import SwiftUI

// MARK: - AppScreen

private struct AppScreenScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private enum AppScreenScrollAnchor {
    static let top = "AppScreenTopAnchor"
}

struct AppScreen<Content: View>: View {
    let title: String?
    let leadingAction: NavAction?
    let trailingAction: NavAction?
    let trailingText: NavTextAction?
    let primaryButton: PrimaryButtonConfig?
    let showsDivider: Bool
    @ViewBuilder let content: () -> Content

    init(
        title: String? = nil,
        leadingAction: NavAction? = nil,
        trailingAction: NavAction? = nil,
        trailingText: NavTextAction? = nil,
        primaryButton: PrimaryButtonConfig? = nil,
        showsDivider: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.leadingAction = leadingAction
        self.trailingAction = trailingAction
        self.trailingText = trailingText
        self.primaryButton = primaryButton
        self.showsDivider = showsDivider
        self.content = content
    }

    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Color.clear
                            .frame(height: 0)
                            .id(AppScreenScrollAnchor.top)

                        GeometryReader { geometry in
                            Color.clear
                                .preference(
                                    key: AppScreenScrollOffsetKey.self,
                                    value: geometry.frame(in: .named("AppScreenScrollView")).minY
                                )
                        }
                        .frame(height: 0)

                        if let title {
                            expandedHeader(title: title)
                        } else if leadingAction != nil || trailingAction != nil || trailingText != nil {
                            plainControlRow
                        }

                        content()
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, primaryButton != nil ? 100 : AppSpacing.md)
                }
                .coordinateSpace(name: "AppScreenScrollView")
                .onPreferenceChange(AppScreenScrollOffsetKey.self) { scrollOffset = $0 }
                .overlay(alignment: .top) {
                    collapsedHeader
                }
                .onDisappear {
                    scrollOffset = 0
                    withAnimation(.none) {
                        proxy.scrollTo(AppScreenScrollAnchor.top, anchor: .top)
                    }
                }

                // Sticky primary CTA
                if let button = primaryButton {
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [AppColor.background.opacity(0), AppColor.background],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 24)

                        AppPrimaryButton(
                            button.label,
                            isEnabled: button.isEnabled,
                            action: button.action
                        )
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.lg)
                        .background(AppColor.background)
                    }
                }
            }
        }
        .background(AppColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var isCollapsed: Bool {
        title != nil && scrollOffset < -24
    }

    @ViewBuilder
    private func expandedHeader(title: String) -> some View {
        if leadingAction == nil {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                Text(title)
                    .font(AppFont.largeTitle.font)
                    .foregroundStyle(AppFont.largeTitle.color)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let trailingAction {
                    navIconButton(trailingAction)
                } else if let trailingText {
                    navTextButton(trailingText)
                }
            }
            .frame(minHeight: 44)
            .opacity(isCollapsed ? 0 : 1)
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    if let leadingAction {
                        navIconButton(leadingAction)
                    }

                    Spacer(minLength: 0)

                    if let trailingAction {
                        navIconButton(trailingAction)
                    } else if let trailingText {
                        navTextButton(trailingText)
                    }
                }
                .frame(height: 44)
                .opacity(isCollapsed ? 0 : 1)

                Text(title)
                    .font(AppFont.largeTitle.font)
                    .foregroundStyle(AppFont.largeTitle.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(isCollapsed ? 0 : 1)
            }
        }
    }

    @ViewBuilder
    private var plainControlRow: some View {
        HStack {
            if let leadingAction {
                navIconButton(leadingAction)
            }

            Spacer(minLength: 0)

            if let trailingAction {
                navIconButton(trailingAction)
            } else if let trailingText {
                navTextButton(trailingText)
            }
        }
        .frame(height: 44)
    }

    @ViewBuilder
    private var collapsedHeader: some View {
        if let title {
            ZStack {
                Text(title)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppFont.sectionHeader.color)
                    .lineLimit(1)
                    .opacity(isCollapsed ? 1 : 0)

                HStack {
                    if let leadingAction {
                        navIconButton(leadingAction)
                            .opacity(isCollapsed ? 1 : 0)
                    } else {
                        Spacer().frame(width: 44)
                    }

                    Spacer(minLength: 0)
                }
            }
            .frame(height: 44)
            .padding(.horizontal, AppSpacing.md)
            .allowsHitTesting(isCollapsed)
        }
    }

    @ViewBuilder
    private func navIconButton(_ action: NavAction) -> some View {
        Button(action: action.action) {
            action.icon.image(size: 17, weight: .semibold)
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func navTextButton(_ action: NavTextAction) -> some View {
        Button(action: action.action) {
            Text(action.label)
                .font(AppFont.label.font)
                .foregroundStyle(AppColor.textPrimary)
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PrimaryButtonConfig

struct PrimaryButtonConfig {
    let label: String
    var isEnabled: Bool = true
    let action: () -> Void
}
