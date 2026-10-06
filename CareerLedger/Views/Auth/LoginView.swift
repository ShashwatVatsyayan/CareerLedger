import SwiftUI
import Supabase

struct LoginView: View {
    @Binding var isLoggedIn: Bool

    init(isLoggedIn: Binding<Bool> = .constant(false)) {
        self._isLoggedIn = isLoggedIn
    }

    enum AuthMode {
        case signIn
        case signUp
    }

    @AppStorage("rememberedEmail") private var rememberedEmail = ""
    @AppStorage("rememberedPassword") private var rememberedPassword = ""
    @AppStorage("autoRememberCredentials") private var autoRememberCredentials = true

    // Legacy storage keys to clean up
    @AppStorage("rememberedUserId") private var legacyRememberedUserId = ""

    @State private var authMode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var studentUID = ""
    @State private var isPasswordVisible = false
    @State private var rememberMe = true
    @State private var hasAutoFilled = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var isAuthenticating = false

    // Forgot Password State
    @State private var showingForgotPasswordSheet = false
    @State private var forgotPasswordEmail = ""
    @State private var forgotPasswordStatusMessage: String? = nil
    @State private var isSendingReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Ambient background with fluid dark/tinted mesh
                backgroundLayer

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Spacer(minLength: 32)

                        // Header Branding
                        headerSection

                        // Mode Selector (Sign In vs Create Account)
                        modeSelector

                        // Credentials Form Card
                        credentialsCard

                        // Security Badge
                        footerSecurityNote

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 22)
                    .frame(maxWidth: 540)
                }
            }
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showingForgotPasswordSheet) {
                forgotPasswordSheet
            }
            .onAppear(perform: loadRememberedCredentials)
        }
    }

    // MARK: - Background Layer
    private var backgroundLayer: some View {
        LiquidMetalBackgroundView(showFluidWaves: true)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Ambient chromatic bloom behind the emblem
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.25, green: 0.45, blue: 0.95).opacity(0.35),
                                Color(red: 0.85, green: 0.20, blue: 0.50).opacity(0.20),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 12)

                // 3D Liquid Metal Emblem Disk
                Circle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.16, green: 0.16, blue: 0.19), location: 0.0),
                                .init(color: Color(red: 0.09, green: 0.09, blue: 0.11), location: 0.5),
                                .init(color: Color.black, location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.45),
                                        Color.white.opacity(0.1),
                                        Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3),
                                        Color.black.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(color: Color.black.opacity(0.6), radius: 14, x: 0, y: 7)

                // Icon with liquid chrome specular gradient
                Image(systemName: "sparkles")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(red: 0.88, green: 0.90, blue: 0.98),
                                Color(red: 0.65, green: 0.75, blue: 0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 0.3, green: 0.5, blue: 1.0).opacity(0.6), radius: 6, x: 0, y: 2)
            }

            VStack(spacing: 6) {
                Text("CareerLedger")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(red: 0.90, green: 0.92, blue: 0.96),
                                Color(red: 0.72, green: 0.76, blue: 0.84)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.black.opacity(0.8), radius: 4, x: 0, y: 2)

                Text("Verifiable Academic & Career Portfolio")
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.68, green: 0.70, blue: 0.76))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Mode Selector
    private var modeSelector: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    authMode = .signIn
                    errorMessage = nil
                    successMessage = nil
                }
            } label: {
                Text("Sign In")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        authMode == .signIn
                            ? LinearGradient(
                                colors: [Color(red: 0.22, green: 0.24, blue: 0.32), Color(red: 0.14, green: 0.15, blue: 0.20)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
                    )
                    .foregroundStyle(authMode == .signIn ? .white : Color(red: 0.65, green: 0.68, blue: 0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        if authMode == .signIn {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        }
                    }
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    authMode = .signUp
                    errorMessage = nil
                    successMessage = nil
                }
            } label: {
                Text("Create Account")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        authMode == .signUp
                            ? LinearGradient(
                                colors: [Color(red: 0.22, green: 0.24, blue: 0.32), Color(red: 0.14, green: 0.15, blue: 0.20)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
                    )
                    .foregroundStyle(authMode == .signUp ? .white : Color(red: 0.65, green: 0.68, blue: 0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        if authMode == .signUp {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        }
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(Color.black.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        }
    }

    // MARK: - Credentials Card
    private var credentialsCard: some View {
        VStack(spacing: 18) {
            // Auto-remembered notification banner
            if hasAutoFilled && authMode == .signIn {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.55))
                    Text("Saved email restored")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(red: 0.85, green: 0.95, blue: 0.88))
                    Spacer()
                    Button("Clear") {
                        clearSavedCredentials()
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.45, green: 0.75, blue: 1.0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.35, blue: 0.25).opacity(0.4),
                            Color(red: 0.08, green: 0.18, blue: 0.12).opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(Color(red: 0.3, green: 0.8, blue: 0.5).opacity(0.3), lineWidth: 0.8)
                }
                .transition(.opacity.combined(with: .scale))
            }

            // Success message
            if let successMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.55))
                        .font(.system(size: 16))
                    Text(successMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(red: 0.85, green: 0.98, blue: 0.88))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(12)
                .background(Color.green.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.green.opacity(0.3), lineWidth: 0.8)
                }
            }

            // Sign Up specific fields
            if authMode == .signUp {
                // Full Name Input
                VStack(alignment: .leading, spacing: 6) {
                    Label("Full Name", systemImage: "person.crop.circle.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.72, green: 0.74, blue: 0.80))

                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.4, green: 0.65, blue: 1.0), Color(red: 0.2, green: 0.45, blue: 0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .font(.system(size: 16))

                        TextField("e.g. Shashwat Vatsyayan", text: $fullName)
                            .autocorrectionDisabled()
                            .font(.system(size: 15))
                            .foregroundStyle(.white)

                        if !fullName.isEmpty {
                            Button { fullName = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.60))
                            }
                        }
                    }
                    .padding(14)
                    .background(fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(fieldBorder)
                }

                // Student UID / Roll Number (Optional, stored in profile/metadata)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("Student UID / Roll Number", systemImage: "graduationcap.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(red: 0.72, green: 0.74, blue: 0.80))
                        Spacer()
                        Text("Optional")
                            .font(.caption2)
                            .foregroundStyle(Color(red: 0.55, green: 0.58, blue: 0.65))
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "number.square.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.65, blue: 0.25), Color(red: 0.85, green: 0.45, blue: 0.15)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .font(.system(size: 16))

                        TextField("e.g. 24BCS12850", text: $studentUID)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(size: 15))
                            .foregroundStyle(.white)

                        if !studentUID.isEmpty {
                            Button { studentUID = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.60))
                            }
                        }
                    }
                    .padding(14)
                    .background(fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(fieldBorder)

                    Text("Stored in your student profile. Supabase Auth always uses your email address below.")
                        .font(.caption2)
                        .foregroundStyle(Color(red: 0.55, green: 0.58, blue: 0.65))
                        .padding(.horizontal, 2)
                }
            }

            // Email Address Input (Required for Auth)
            VStack(alignment: .leading, spacing: 6) {
                Label("Email Address", systemImage: "envelope.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.72, green: 0.74, blue: 0.80))

                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.65, blue: 1.0), Color(red: 0.2, green: 0.45, blue: 0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .font(.system(size: 16))

                    TextField("e.g. 24bcs12850@cuchd.in or name@gmail.com", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .font(.system(size: 15))
                        .foregroundStyle(.white)

                    if !email.isEmpty {
                        Button { email = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.60))
                        }
                    }
                }
                .padding(14)
                .background(fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(fieldBorder)
            }

            // Password Input
            VStack(alignment: .leading, spacing: 6) {
                Label("Password", systemImage: "lock.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.72, green: 0.74, blue: 0.80))

                HStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.85, green: 0.35, blue: 0.75), Color(red: 0.55, green: 0.25, blue: 0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .font(.system(size: 16))

                    Group {
                        if isPasswordVisible {
                            TextField(authMode == .signUp ? "Choose password (min 6 chars)" : "Enter your password", text: $password)
                        } else {
                            SecureField(authMode == .signUp ? "Choose password (min 6 chars)" : "Enter your password", text: $password)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .textContentType(authMode == .signUp ? .newPassword : .password)
                    .autocorrectionDisabled()
                    .font(.system(size: 15))
                    .foregroundStyle(.white)

                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.60))
                    }
                }
                .padding(14)
                .background(fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(fieldBorder)

                // Forgot Password link for Sign In
                if authMode == .signIn {
                    HStack {
                        Spacer()
                        Button {
                            forgotPasswordEmail = email
                            forgotPasswordStatusMessage = nil
                            showingForgotPasswordSheet = true
                        } label: {
                            Text("Forgot password?")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color(red: 0.45, green: 0.75, blue: 1.0))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 2)
                }
            }

            // Remember Me Toggle (Sign In only)
            if authMode == .signIn {
                Toggle(isOn: $rememberMe) {
                    HStack(spacing: 8) {
                        Image(systemName: rememberMe ? "lock.square.stack.fill" : "lock.square.stack")
                            .foregroundStyle(rememberMe ? Color(red: 0.45, green: 0.75, blue: 1.0) : Color.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-remember email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                            Text("Saved securely on this device")
                                .font(.caption2)
                                .foregroundStyle(Color(red: 0.60, green: 0.62, blue: 0.68))
                        }
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.25, green: 0.50, blue: 0.95)))
                .padding(.horizontal, 4)
            }

            // Error display
            if let errorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.45))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(10)
                .background(Color.red.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.red.opacity(0.3), lineWidth: 0.8)
                }
                .transition(.opacity)
            }

            // Action Button
            VStack(spacing: 14) {
                LiquidMetalButton(
                    label: isAuthenticating
                        ? (authMode == .signIn ? "Signing In..." : "Creating Account...")
                        : (authMode == .signIn ? "Login to Ledger" : "Create Account"),
                    icon: isAuthenticating
                        ? "arrow.triangle.2.circlepath"
                        : (authMode == .signIn ? "sparkles" : "person.badge.plus"),
                    height: 52
                ) {
                    performAuthAction()
                }
                .disabled(isAuthenticating)

                // Alternate mode switch button
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        authMode = (authMode == .signIn ? .signUp : .signIn)
                        errorMessage = nil
                        successMessage = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(authMode == .signIn ? "Don't have an account?" : "Already have an account?")
                            .foregroundStyle(Color(red: 0.65, green: 0.68, blue: 0.75))
                        Text(authMode == .signIn ? "Sign Up" : "Sign In")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(red: 0.45, green: 0.75, blue: 1.0))
                    }
                    .font(.footnote)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
        .padding(24)
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.15, green: 0.15, blue: 0.18), location: 0.0),
                    .init(color: Color(red: 0.09, green: 0.09, blue: 0.11), location: 0.4),
                    .init(color: Color(red: 0.05, green: 0.05, blue: 0.06), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.08),
                            Color(red: 0.35, green: 0.55, blue: 0.95).opacity(0.2),
                            Color.black.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .shadow(color: Color.black.opacity(0.6), radius: 25, x: 0, y: 12)
        .shadow(color: Color(red: 0.2, green: 0.3, blue: 0.6).opacity(0.12), radius: 30, x: 0, y: 0)
    }

    // MARK: - Field Styling Helpers
    private var fieldBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.09, green: 0.09, blue: 0.11),
                Color(red: 0.05, green: 0.05, blue: 0.07)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 14)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Color.white.opacity(0.04),
                        Color.black.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
    }

    // MARK: - Footer Security Note
    private var footerSecurityNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.blue)
            Text("Supabase Cloud Auth • Local SwiftData Encrypted")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Forgot Password Sheet
    private var forgotPasswordSheet: some View {
        NavigationStack {
            ZStack {
                LiquidMetalBackgroundView(showFluidWaves: false)

                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(red: 0.45, green: 0.75, blue: 1.0))
                            .padding(.top, 10)

                        Text("Reset Password")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Enter your registered email address to receive a secure password reset link.")
                            .font(.subheadline)
                            .foregroundStyle(Color(red: 0.70, green: 0.72, blue: 0.78))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Email Address", systemImage: "envelope.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(red: 0.72, green: 0.74, blue: 0.80))

                        TextField("e.g. student@cuchd.in or name@gmail.com", text: $forgotPasswordEmail)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(fieldBorder)
                            .foregroundStyle(.white)
                    }

                    if let forgotPasswordStatusMessage {
                        Text(forgotPasswordStatusMessage)
                            .font(.footnote)
                            .foregroundStyle(Color(red: 0.85, green: 0.95, blue: 0.88))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    LiquidMetalButton(
                        label: isSendingReset ? "Sending..." : "Send Reset Link",
                        icon: "paperplane.fill",
                        height: 48
                    ) {
                        sendPasswordReset()
                    }
                    .disabled(isSendingReset)

                    Spacer()
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        showingForgotPasswordSheet = false
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - Actions
    private func loadRememberedCredentials() {
        // Clean legacy demo student UID and password if present
        if legacyRememberedUserId == "24BCS12850" || legacyRememberedUserId.lowercased().contains("demo") {
            legacyRememberedUserId = ""
            rememberedPassword = ""
        }

        if !rememberedEmail.isEmpty && rememberedEmail.contains("@") {
            email = rememberedEmail
            password = rememberedPassword
            rememberMe = autoRememberCredentials
            hasAutoFilled = true
        } else {
            rememberMe = autoRememberCredentials
        }
    }

    private func isValidEmail(_ testEmail: String) -> Bool {
        let trimmed = testEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    private func performAuthAction() {
        errorMessage = nil
        successMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate that an email is used, not just a student UID alone
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }

        guard isValidEmail(trimmedEmail) else {
            if !trimmedEmail.contains("@") {
                errorMessage = "Please enter a full email address (e.g. \(trimmedEmail.lowercased())@cuchd.in or name@gmail.com). A student UID alone cannot be used as the login identifier."
            } else {
                errorMessage = "Please enter a valid email address format."
            }
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Please enter your password."
            return
        }

        if authMode == .signUp {
            let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                errorMessage = "Please enter your full name."
                return
            }

            guard password.count >= 6 else {
                errorMessage = "Password must be at least 6 characters long."
                return
            }

            isAuthenticating = true

            Task {
                do {
                    let response = try await SupabaseManager.shared.signUp(
                        email: trimmedEmail,
                        password: password,
                        fullName: trimmedName,
                        studentUID: studentUID.trimmingCharacters(in: .whitespacesAndNewlines)
                    )

                    await MainActor.run {
                        isAuthenticating = false
                        if response.session != nil {
                            // Immediate session established (no email confirmation required)
                            if rememberMe {
                                rememberedEmail = trimmedEmail
                                rememberedPassword = password
                                autoRememberCredentials = true
                            }
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                isLoggedIn = true
                            }
                        } else {
                            // Confirmation email sent
                            successMessage = "Account registered successfully! A confirmation link has been sent to \(trimmedEmail). Please confirm your email in your inbox before signing in."
                            authMode = .signIn
                        }
                    }
                } catch {
                    await MainActor.run {
                        isAuthenticating = false
                        errorMessage = error.localizedDescription
                    }
                }
            }
        } else {
            // Sign In
            isAuthenticating = true

            Task {
                do {
                    _ = try await SupabaseManager.shared.signIn(
                        email: trimmedEmail,
                        password: password
                    )

                    await MainActor.run {
                        isAuthenticating = false
                        if rememberMe {
                            rememberedEmail = trimmedEmail
                            rememberedPassword = password
                            autoRememberCredentials = true
                        } else {
                            clearSavedCredentials()
                        }
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                            isLoggedIn = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        isAuthenticating = false
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private func sendPasswordReset() {
        let trimmed = forgotPasswordEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmed) else {
            forgotPasswordStatusMessage = "Please enter a valid email address."
            return
        }

        isSendingReset = true
        forgotPasswordStatusMessage = nil

        Task {
            do {
                try await SupabaseManager.shared.resetPassword(email: trimmed)
                await MainActor.run {
                    isSendingReset = false
                    forgotPasswordStatusMessage = "Password reset instructions have been sent to \(trimmed). Please check your inbox."
                }
            } catch {
                await MainActor.run {
                    isSendingReset = false
                    forgotPasswordStatusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func clearSavedCredentials() {
        rememberedEmail = ""
        rememberedPassword = ""
        legacyRememberedUserId = ""
        email = ""
        password = ""
        hasAutoFilled = false
    }
}

#Preview {
    LoginView()
}
