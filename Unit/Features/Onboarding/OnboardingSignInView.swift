//
//  OnboardingSignInView.swift
//  Unit
//
//  Screen 9 — Optional Sign in with Apple.
//  The cycle is already saved at this point. Sign-in is an enhancement.
//

import SwiftUI
import AuthenticationServices

struct OnboardingSignInView: View {
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            AtlasTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .padding(.bottom, AtlasTheme.Spacing.xs)

                    Text("Save your cycle to iCloud")
                        .font(AtlasTheme.Typography.hero)
                        .foregroundStyle(AtlasTheme.Colors.textPrimary)

                    Text("Your program and progress sync across devices automatically with Sign in with Apple.")
                        .font(AtlasTheme.Typography.body)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AtlasTheme.Spacing.xl)

                Spacer()

                VStack(spacing: AtlasTheme.Spacing.md) {
                    // Sign in with Apple (system button)
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = []
                    } onCompletion: { result in
                        // Auth handling would go here in a real implementation
                        onFinish()
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))
                    .padding(.horizontal, AtlasTheme.Spacing.xl)

                    // Skip link
                    Button(action: onFinish) {
                        Text("Skip for now")
                            .font(AtlasTheme.Typography.body)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            .frame(height: 44)
                    }
                }
                .padding(.bottom, AtlasTheme.Spacing.xxxl)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    OnboardingSignInView { }
        .preferredColorScheme(.dark)
}
