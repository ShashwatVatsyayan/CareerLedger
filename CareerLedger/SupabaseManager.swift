import Foundation
import Supabase
import Auth

public enum AuthSecurityError: LocalizedError {
    case unauthenticatedSession
    case sessionExpired
    case unauthorizedAccess(reason: String)

    public var errorDescription: String? {
        switch self {
        case .unauthenticatedSession:
            return "Authentication required: A valid Supabase session token is required to perform this operation."
        case .sessionExpired:
            return "Session expired: Security token has expired. Please log in again to renew authorization."
        case .unauthorizedAccess(let reason):
            return "Unauthorized: \(reason)"
        }
    }
}

final class SupabaseManager: @unchecked Sendable {
    static let shared = SupabaseManager()

    let client: SupabaseClient
    
    private init(){
        client = SupabaseClient(
            supabaseURL: URL(string: "https://vtdvvjljfleudshkcnzi.supabase.co")!,
            supabaseKey: "sb_publishable_dwP4_8RD4ZOWZld5rFXWQQ_FYikfKx9"
        )
    }

    var currentUser: User? {
        client.auth.currentUser
    }

    var currentUserEmail: String? {
        client.auth.currentUser?.email
    }

    var currentSession: Session? {
        client.auth.currentSession
    }

    var currentUserFullName: String {
        if let session = client.auth.currentSession,
           case .string(let name) = session.user.userMetadata["full_name"] {
            return name
        }
        return ""
    }

    var currentUserUUID: UUID? {
        client.auth.currentSession?.user.id
    }

    /// Strict security validation helper:
    /// Audits and confirms that an active, non-expired session token exists.
    /// Throws AuthSecurityError if unauthenticated or expired.
    @discardableResult
    func validateActiveSession() throws -> (session: Session, userUUID: UUID) {
        guard let session = client.auth.currentSession else {
            throw AuthSecurityError.unauthenticatedSession
        }
        if session.isExpired {
            throw AuthSecurityError.sessionExpired
        }
        return (session, session.user.id)
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> Session {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let session = try await client.auth.signIn(email: trimmedEmail, password: password)

        let fullName: String
        if case .string(let name) = session.user.userMetadata["full_name"] {
            fullName = name
        } else {
            fullName = ""
        }
        await createProfileRecordIfNeeded(userUUID: session.user.id, fullName: fullName)
        return session
    }

    @discardableResult
    func signUp(email: String, password: String, fullName: String, studentUID: String) async throws -> AuthResponse {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var metadata: [String: AnyJSON] = [
            "full_name": .string(fullName)
        ]
        let trimmedUID = studentUID.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedUID.isEmpty {
            metadata["student_uid"] = .string(trimmedUID)
        }

        let response = try await client.auth.signUp(
            email: trimmedEmail,
            password: password,
            data: metadata
        )

        // Note: Using the authenticated Supabase user's UUID (response.user.id), NEVER the student UID
        if let session = response.session {
            await createProfileRecordIfNeeded(userUUID: session.user.id, fullName: fullName)
        }
        return response
    }

    func resetPassword(email: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        try await client.auth.resetPasswordForEmail(trimmedEmail)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func createProfileRecordIfNeeded(userUUID: UUID, fullName: String) async {
        // Enforce strict authorization check: caller must match authenticated session UID
        guard let (_, sessionUID) = try? validateActiveSession(), sessionUID == userUUID else {
            #if DEBUG
            print("[Security Audit] Rejected createProfileRecordIfNeeded: Unauthenticated or mismatched session UUID")
            #endif
            return
        }

        struct ProfilePayload: Encodable {
            let user_id: UUID
            let full_name: String
            let university: String
        }

        let payload = ProfilePayload(
            user_id: userUUID,
            full_name: fullName.isEmpty ? "Student" : fullName,
            university: "Chandigarh University"
        )

        do {
            try await client
                .from("profiles")
                .upsert(payload, onConflict: "user_id")
                .execute()
        } catch {
            do {
                try await client
                    .from("profiles")
                    .insert(payload)
                    .execute()
            } catch {
                // If profile already exists or trigger handled it, continue without failing
            }
        }
    }
}
