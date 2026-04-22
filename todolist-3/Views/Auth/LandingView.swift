//
//  LandingView.swift
//  todolist-3
//
//  LAYER: View
//  PURPOSE: The first screen an unauthenticated user sees.
//           Presents the app's branding and routes to LoginView or SignUpView.
//

import SwiftUI

// =============================================================================
// MARK: - LandingView
// =============================================================================

struct LandingView: View {

    @EnvironmentObject private var authVM: AuthViewModel

    /// Controls which auth sheet is showing (nil = neither).
    @State private var destination: AuthDestination? = nil

    // Convenience enum so a single @State drives both sheets cleanly.
    enum AuthDestination: Identifiable {
        case login, signUp
        var id: Self { self }
    }

    var body: some View {
        ZStack {
            // ── Animated Gradient Background ──────────────────────────────
            LinearGradient(
                colors: [
                    Color(hue: 0.62, saturation: 0.75, brightness: 0.22),
                    Color(hue: 0.72, saturation: 0.60, brightness: 0.15),
                    Color(hue: 0.58, saturation: 0.55, brightness: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // ── Decorative Blobs ──────────────────────────────────────────
            decorativeBlobs

            // ── Main Content Column ───────────────────────────────────────
            VStack(spacing: 0) {
                Spacer()

                // Logo + headline
                brandingBlock

                Spacer()

                // CTA buttons
                ctaButtons
                    .padding(.horizontal, 32)
                    .padding(.bottom, 56)
            }
        }
        // Present Login or SignUp as a full-screen cover so the landing
        // screen stays underneath and the user can dismiss if needed.
        .fullScreenCover(item: $destination) { dest in
            switch dest {
            case .login:   LoginView()
            case .signUp:  SignUpView()
            }
        }
    }

    // MARK: - Branding Block

    private var brandingBlock: some View {
        VStack(spacing: 20) {
            // App icon circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hue: 0.62, saturation: 0.80, brightness: 0.90),
                                Color(hue: 0.72, saturation: 0.70, brightness: 0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(
                        color: Color(hue: 0.62, saturation: 0.75, brightness: 0.80).opacity(0.5),
                        radius: 30,
                        y: 10
                    )

                Image(systemName: "checklist")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 10) {
                Text("To-Do Pro")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Organise your day.\nStay on top of everything.")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.70))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - CTA Buttons

    private var ctaButtons: some View {
        VStack(spacing: 14) {
            // Primary – Sign Up
            Button {
                destination = .signUp
            } label: {
                Text("Get Started")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hue: 0.62, saturation: 0.75, brightness: 0.20))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .white.opacity(0.20), radius: 12, y: 4)
            }
            .buttonStyle(.plain)

            // Secondary – Log In
            Button {
                destination = .login
            } label: {
                Text("I already have an account")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.30), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Decorative Blobs

    private var decorativeBlobs: some View {
        GeometryReader { geo in
            // Top-right blob
            Circle()
                .fill(
                    Color(hue: 0.62, saturation: 0.60, brightness: 0.50).opacity(0.20)
                )
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: geo.size.width - 100, y: -80)

            // Bottom-left blob
            Circle()
                .fill(
                    Color(hue: 0.72, saturation: 0.55, brightness: 0.45).opacity(0.20)
                )
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -120, y: geo.size.height - 180)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview
struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
            .environmentObject(AuthViewModel())
    }
}
