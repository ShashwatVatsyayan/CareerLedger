import SwiftUI

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 14) {
                    Image(systemName: "graduationcap.circle.fill")
                        .font(.system(size: 76))
                        .foregroundStyle(.blue.gradient)
                        .symbolEffect(.pulse)

                    Text("CareerLedger")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Sign in to manage your academic portfolio.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 14) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            isLoggedIn = true
                        }
                    } label: {
                        Label("Login", systemImage: "arrow.right.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        email = "student@example.com"
                        password = "password"
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            isLoggedIn = true
                        }
                    } label: {
                        Text("Continue as Demo Student")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(20)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.18), Color.purple.opacity(0.10), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

#Preview {
    LoginView()
}
