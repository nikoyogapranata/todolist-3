//
//  SignUpView.swift
//  todolist-3
//
//  LAYER: View
//  PURPOSE: New account registration form (email + password + confirm password).
//           Validates inputs locally before calling AuthViewModel.signUp().
//           Compatible with iOS 16.4+.
//

import SwiftUI

// =============================================================================
// MARK: - SignUpView
// =============================================================================

struct SignUpView: View {

    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    // ── Form State ────────────────────────────────────────────────────────────

    @State private var email: String            = ""
    @State private var password: String         = ""
    @State private var confirmPassword: String  = ""
    @State private var showPassword: Bool       = false
    @State private var showConfirm: Bool        = false

    /// Local validation error shown before calling Firebase.
    @State private var localError: String?      = nil

    @FocusState private var focusedField: Field?

    enum Field { case email, password, confirmPassword }

    // ── Body ──────────────────────────────────────────────────────────────────

    var body: some View {
        NavigationStack {
            ZStack {
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

                ScrollView {
                    VStack(spacing: 32) {
                        headerBlock
                        formCard
                        signUpButton
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.88))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Header

    private var headerBlock: some View {
        VStack(spacing: 8) {
            Text("Create account")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Start organising your tasks today")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(spacing: 0) {

            // Email
            SignUpTextField(
                label: "Email",
                icon: "envelope.fill",
                text: $email,
                keyboardType: .emailAddress,
                contentType: .emailAddress,
                focusedField: $focusedField,
                field: .email,
                nextField: .password
            )

            Divider().background(Color.white.opacity(0.08))

            // Password
            SignUpSecureField(
                label: "Password",
                icon: "lock.fill",
                text: $password,
                showText: $showPassword,
                focusedField: $focusedField,
                field: .password,
                nextField: .confirmPassword
            )

            Divider().background(Color.white.opacity(0.08))

            // Confirm password
            SignUpSecureField(
                label: "Confirm Password",
                icon: "lock.rotation",
                text: $confirmPassword,
                showText: $showConfirm,
                focusedField: $focusedField,
                field: .confirmPassword,
                nextField: nil,
                onSubmit: { attemptSignUp() }
            )

            // Password strength hint
            if !password.isEmpty {
                strengthHint
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: password.isEmpty)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .overlay(alignment: .bottom) {
            if let msg = localError ?? authVM.errorMessage {
                Text(msg)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hue: 0.02, saturation: 0.85, brightness: 1.0))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(hue: 0.02, saturation: 0.85, brightness: 1.0).opacity(0.15))
                    )
                    .offset(y: 46)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: localError ?? authVM.errorMessage)
    }

    // MARK: - Password Strength Hint

    private var strengthHint: some View {
        let strength = passwordStrength(password)
        return HStack(spacing: 6) {
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(i < strength.level ? strength.color : Color.white.opacity(0.15))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.2), value: strength.level)
            }
            Text(strength.label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(strength.color)
        }
        .padding(.top, 8)
    }

    // MARK: - Sign-Up Button

    private var signUpButton: some View {
        Button {
            attemptSignUp()
        } label: {
            ZStack {
                if authVM.isLoading {
                    ProgressView()
                        .tint(Color(hue: 0.62, saturation: 0.75, brightness: 0.22))
                } else {
                    Text("Create Account")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hue: 0.62, saturation: 0.75, brightness: 0.20))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .white.opacity(0.15), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(authVM.isLoading)
        .opacity(authVM.isLoading ? 0.8 : 1.0)
        .padding(.top, 20) // Clears floating error label
    }

    // MARK: - Validation & Action

    private func attemptSignUp() {
        localError = nil
        authVM.errorMessage = nil

        guard validate() else { return }

        // Use the fully-qualified _Concurrency.Task to avoid a name collision
        // with the project's own `Task` Codable model.
        _Concurrency.Task {
            await authVM.signUp(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
        }
    }

    @discardableResult
    private func validate() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        if trimmedEmail.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            localError = "Please fill in all fields."
            return false
        }
        if !isValidEmail(trimmedEmail) {
            localError = "That doesn't look like a valid email address."
            return false
        }
        if password.count < 6 {
            localError = "Password must be at least 6 characters."
            return false
        }
        if password != confirmPassword {
            localError = "Passwords don't match."
            return false
        }
        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Password Strength

    private struct StrengthInfo {
        let level: Int   // 1 (weak) | 2 (fair) | 3 (strong)
        let label: String
        let color: Color
    }

    private func passwordStrength(_ pwd: String) -> StrengthInfo {
        let hasUpper  = pwd.range(of: "[A-Z]",      options: .regularExpression) != nil
        let hasDigit  = pwd.range(of: "[0-9]",      options: .regularExpression) != nil
        let hasSymbol = pwd.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        let isLong    = pwd.count >= 10

        let score = [hasUpper, hasDigit, hasSymbol, isLong].filter { $0 }.count

        switch score {
        case 0...1: return StrengthInfo(level: 1, label: "Weak",   color: Color(hue: 0.02, saturation: 0.80, brightness: 0.90))
        case 2...3: return StrengthInfo(level: 2, label: "Fair",   color: Color(hue: 0.10, saturation: 0.85, brightness: 0.95))
        default:    return StrengthInfo(level: 3, label: "Strong", color: Color(hue: 0.38, saturation: 0.70, brightness: 0.75))
        }
    }
}

// =============================================================================
// MARK: - Reusable Field Sub-Views (file-private)
// =============================================================================

private struct SignUpTextField: View {
    let label: String
    let icon: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType? = nil

    @FocusState.Binding var focusedField: SignUpView.Field?
    let field: SignUpView.Field
    var nextField: SignUpView.Field? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 22)

            TextField(label, text: $text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .textContentType(contentType)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .focused($focusedField, equals: field)
                .submitLabel(nextField != nil ? .next : .done)
                .onSubmit {
                    if let next = nextField { focusedField = next }
                    else { focusedField = nil }
                }
                .tint(.white)
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
    }
}

private struct SignUpSecureField: View {
    let label: String
    let icon: String
    @Binding var text: String
    @Binding var showText: Bool

    @FocusState.Binding var focusedField: SignUpView.Field?
    let field: SignUpView.Field
    var nextField: SignUpView.Field? = nil
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 22)

            Group {
                if showText {
                    TextField(label, text: $text)
                        .textContentType(.newPassword)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } else {
                    SecureField(label, text: $text)
                        .textContentType(.newPassword)
                }
            }
            .font(.system(size: 16, design: .rounded))
            .foregroundColor(.white)
            .focused($focusedField, equals: field)
            .submitLabel(nextField != nil ? .next : .done)
            .onSubmit {
                if let next = nextField { focusedField = next }
                else { onSubmit?() }
            }
            .tint(.white)

            Button { showText.toggle() } label: {
                Image(systemName: showText ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.45))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
    }
}

// MARK: - Preview
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
