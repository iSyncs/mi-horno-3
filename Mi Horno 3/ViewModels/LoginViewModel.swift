// LoginViewModel.swift
import SwiftUI
import Combine

enum AuthMode: Equatable { case register, login }

// MARK: - API Models

struct AuthResponse: Codable {
    let accessToken:  String
    let refreshToken: String
    let user:         AuthUser
    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct AuthUser: Codable {
    let id:           Int
    let fullName:     String?
    let email:        String
    let authProvider: String
    let avatarUrl:    String?
    let userType:     String
    enum CodingKeys: String, CodingKey {
        case id
        case fullName     = "full_name"
        case email
        case authProvider = "auth_provider"
        case avatarUrl    = "avatar_url"
        case userType     = "user_type"
    }
}

// MARK: - API Errors

enum APIError: Error {
    case emailExists
    case wrongPassword
    case notFound
    case validation(String)
    case server
    case network

    var message: String {
        switch self {
        case .emailExists:       return "El correo ya está registrado"
        case .wrongPassword:     return "Contraseña incorrecta"
        case .notFound:          return "No existe una cuenta con ese correo"
        case .validation(let m): return m
        case .server:            return "Error del servidor. Intenta de nuevo."
        case .network:           return "Sin conexión. Revisa tu internet."
        }
    }
}

// MARK: - LoginViewModel

final class LoginViewModel: ObservableObject {

    @Published var mode:         AuthMode = .register
    @Published var name:         String   = ""
    @Published var lastName:     String   = ""
    @Published var email:        String   = ""
    @Published var password:     String   = ""
    @Published var isLoading:    Bool     = false
    @Published var errorMessage: String?  = nil

    private let baseURL = Config.baseURL

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 15
        return URLSession(configuration: cfg)
    }()

    // MARK: - Autenticar

    func authenticate(router: AppRouter, lm: LocalizationManager) {
        errorMessage = nil
        let emailClean = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if mode == .register {
            let nameClean = name.trimmingCharacters(in: .whitespaces)
            guard !nameClean.isEmpty       else { errorMessage = lm.s(L.loginErrName);     return }
            guard emailClean.contains("@") else { errorMessage = lm.s(L.loginErrEmail);    return }
            guard password.count >= 6      else { errorMessage = lm.s(L.loginErrPassword); return }
            Task { await register(name: nameClean, email: emailClean, router: router, lm: lm) }
        } else {
            guard !emailClean.isEmpty, !password.isEmpty else {
                errorMessage = lm.s(L.loginErrFields); return
            }
            Task { await login(email: emailClean, router: router, lm: lm) }
        }
    }

    @MainActor
    private func register(name: String, email: String, router: AppRouter, lm: LocalizationManager) async {
        isLoading = true
        defer { isLoading = false }
        let fullName = [name, lastName.trimmingCharacters(in: .whitespaces)]
            .filter { !$0.isEmpty }.joined(separator: " ")
        let body: [String: Any] = ["full_name": fullName, "email": email, "password": password]
        do {
            let r = try await post("/auth/register", body: body)
            saveSession(r, router: router)
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = APIError.network.message
        }
    }

    @MainActor
    private func login(email: String, router: AppRouter, lm: LocalizationManager) async {
        isLoading = true
        defer { isLoading = false }
        let body: [String: Any] = ["email": email, "password": password]
        do {
            let r = try await post("/auth/login", body: body)
            saveSession(r, router: router)
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = APIError.network.message
        }
    }

    // MARK: - Session

    private func saveSession(_ r: AuthResponse, router: AppRouter) {
        UserDefaults.standard.set(r.accessToken,  forKey: "h3_access_token")
        UserDefaults.standard.set(r.refreshToken, forKey: "h3_refresh_token")
        router.login(
            id: r.user.id,
            name:  r.user.fullName ?? r.user.email,
            email: r.user.email
        )
        Task { await fetchProfileName(router: router) }
        Task {
            if SurveyViewModel.hasPendingSubmission() {
                await SurveyViewModel.attemptBackgroundSync()
            }
            await SurveyViewModel.refreshCompletionStatus()
        }
    }

    /// GET /profile — obtiene first_name + last_name actualizados y corrige el router
    @MainActor
    private func fetchProfileName(router: AppRouter) async {
        guard let token = UserDefaults.standard.string(forKey: "h3_access_token"),
              let url   = URL(string: baseURL + "/profile") else { return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, _) = try? await session.data(for: req),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let first = json["first_name"] as? String, !first.isEmpty
        else { return }

        let last     = json["last_name"] as? String ?? ""
        let fullName = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        router.updateDisplayName(fullName)   // actualiza userName + UserDefaults
    }

    // MARK: - HTTP

    private func post(_ path: String, body: [String: Any]) async throws -> AuthResponse {
        guard let url = URL(string: baseURL + path) else { throw APIError.network }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.network
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.network }

        switch http.statusCode {
        case 200, 201:
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        case 401:
            throw APIError.wrongPassword
        case 404:
            throw APIError.notFound
        case 409:
            throw APIError.emailExists
        case 422:
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Datos inválidos"
            throw APIError.validation(msg)
        default:
            throw APIError.server
        }
    }
}
