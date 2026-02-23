import Foundation

struct OAuthStartRoute {
    let path: String?
    let reason: String?
}

enum ConnectionRouting {
    static func oauthStartPath(for platform: PlatformID) -> OAuthStartRoute {
        switch platform {
        case .youtube:
            return OAuthStartRoute(path: "google", reason: nil)
        case .instagram:
            return OAuthStartRoute(path: nil, reason: "Instagram connection is provided via Facebook OAuth. Connect Facebook first.")
        case .discord:
            return OAuthStartRoute(path: nil, reason: "Discord uses webhook connection and is not yet wired in this desktop build.")
        default:
            return OAuthStartRoute(path: platform.rawValue, reason: nil)
        }
    }
}

struct BackendOAuthStartResponse: Decodable {
    let authorizationURL: String

    enum CodingKeys: String, CodingKey {
        case authorizationURL = "authorization_url"
    }
}

struct BackendAccount: Decodable {
    let id: UUID
    let platform: String
    let accountName: String
    let isActive: Bool
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case platform
        case accountName = "account_name"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

enum BackendError: Error {
    case invalidURL
    case badResponse(Int)
    case decodeFailed

    var message: String {
        switch self {
        case .invalidURL:
            return "Invalid backend URL configuration."
        case .badResponse(let code):
            return "Backend request failed with status \(code)."
        case .decodeFailed:
            return "Failed to decode backend response."
        }
    }
}

struct BackendService {
    let baseURL: URL

    init(baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.baseURL = baseURL
    }

    func startOAuth(platform: PlatformID) async throws -> URL {
        let route = ConnectionRouting.oauthStartPath(for: platform)
        if let reason = route.reason {
            throw NSError(domain: "OmniPostD", code: 1, userInfo: [NSLocalizedDescriptionKey: reason])
        }
        guard let path = route.path else {
            throw BackendError.invalidURL
        }

        let url = baseURL.appending(path: "auth/\(path)")
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw BackendError.invalidURL }
        guard (200...299).contains(http.statusCode) else { throw BackendError.badResponse(http.statusCode) }
        guard let payload = try? JSONDecoder().decode(BackendOAuthStartResponse.self, from: data) else {
            throw BackendError.decodeFailed
        }
        guard let authURL = URL(string: payload.authorizationURL) else {
            throw BackendError.decodeFailed
        }
        return authURL
    }

    func fetchAccounts() async throws -> [SocialAccount] {
        let url = baseURL.appending(path: "api/accounts")
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw BackendError.invalidURL }
        guard (200...299).contains(http.statusCode) else { throw BackendError.badResponse(http.statusCode) }

        let decoder = JSONDecoder()
        guard let rows = try? decoder.decode([BackendAccount].self, from: data) else {
            throw BackendError.decodeFailed
        }

        let iso = ISO8601DateFormatter()

        return rows.compactMap { row in
            guard let platform = PlatformID(rawValue: row.platform) else { return nil }
            let created = row.createdAt.flatMap { iso.date(from: $0) } ?? Date()
            return SocialAccount(
                id: row.id,
                platform: platform,
                accountName: row.accountName,
                isActive: row.isActive,
                createdAt: created
            )
        }
        .sorted { $0.platform.rawValue < $1.platform.rawValue }
    }

    func disconnect(accountID: UUID) async throws {
        let endpoint = baseURL.appending(path: "api/accounts/\(accountID.uuidString)")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "DELETE"

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BackendError.invalidURL }
        guard (200...299).contains(http.statusCode) else { throw BackendError.badResponse(http.statusCode) }
    }
}
