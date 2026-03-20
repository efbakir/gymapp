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
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    AppIcon.cloud.image(size: 36, weight: .semibold)
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.bottom, AppSpacing.sm)

                    Text("Save your cycle to iCloud")
                        .font(AppFont.largeTitle.font)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("Your program and progress sync across devices automatically with Sign in with Apple.")
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.xl)

                Spacer()

                VStack(spacing: AppSpacing.md) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = []
                    } onCompletion: { result in
                        onFinish()
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    .padding(.horizontal, AppSpacing.xl)

                    VStack(spacing: AppSpacing.sm) {
                        AppSecondaryButton("Skip for now") {
                            onFinish()
                        }
                        .padding(.horizontal, AppSpacing.xl)

                        Text("Your cycle is saved on this device.")
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    OnboardingSignInView { }
}
