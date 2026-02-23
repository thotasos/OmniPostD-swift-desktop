import Foundation
import AppKit
import CryptoKit

struct OAuthPending {
    let provider: OAuthProvider
    let state: String
    let codeVerifier: String?
}

enum OAuthProvider: String {
    case facebook
    case twitter
    case google
    case reddit
    case linkedin
    case pinterest
    case tiktok
    case snapchat
}

struct OAuthClientCredentials: Codable {
    let clientID: String
    let clientSecret: String
}

struct OAuthCredentialFile: Codable {
    let facebook: OAuthClientCredentials?
    let twitter: OAuthClientCredentials?
    let google: OAuthClientCredentials?
    let reddit: OAuthClientCredentials?
    let linkedin: OAuthClientCredentials?
    let pinterest: OAuthClientCredentials?
    let tiktok: OAuthClientCredentials?
    let snapchat: OAuthClientCredentials?
}

enum StandaloneOAuthError: Error {
    case missingCredentials(String)
    case unsupported(String)
    case invalidCallback
    case stateMismatch
    case missingCode
    case tokenExchangeFailed(String)
    case profileFetchFailed(String)

    var message: String {
        switch self {
        case .missingCredentials(let platform):
            return "Missing OAuth credentials for \(platform). Update ~/Library/Application Support/OmniPostD/oauth_credentials.json"
        case .unsupported(let reason):
            return reason
        case .invalidCallback:
            return "Invalid callback URL. Paste the full redirected URL from the browser."
        case .stateMismatch:
            return "OAuth state mismatch. Start connect again."
        case .missingCode:
            return "Authorization code missing from callback URL."
        case .tokenExchangeFailed(let reason):
            return "Token exchange failed: \(reason)"
        case .profileFetchFailed(let reason):
            return "Profile lookup failed: \(reason)"
        }
    }
}

struct OAuthStartResult {
    let message: String
    let requiresCallbackPaste: Bool
    let pending: OAuthPending?
}

struct ConnectedProfile {
    let accountID: String
    let accountName: String
    let platform: PlatformID
}

struct StandaloneOAuthService {
    private let callbackURI = "http://localhost:8765/callback"

    func beginConnection(for platform: PlatformID) throws -> OAuthStartResult {
        if platform == .instagram {
            throw StandaloneOAuthError.unsupported("Instagram connection uses Facebook scopes. Connect Facebook and ensure instagram scopes are granted.")
        }
        if platform == .discord {
            throw StandaloneOAuthError.unsupported("Discord requires webhook URL setup (not OAuth) in this build.")
        }
        if platform == .tumblr {
            throw StandaloneOAuthError.unsupported("Tumblr OAuth1 is not yet implemented in this standalone build.")
        }

        guard let provider = provider(for: platform) else {
            throw StandaloneOAuthError.unsupported("Unsupported platform: \(platform.rawValue)")
        }
        let creds = try credentials(for: provider)

        let state = randomURLSafe(length: 32)
        let codeVerifier = provider == .twitter ? randomURLSafe(length: 64) : nil
        let codeChallenge = codeVerifier.map(sha256Base64URL)

        let authURL = authorizationURL(provider: provider, creds: creds, state: state, codeChallenge: codeChallenge)
        NSWorkspace.shared.open(authURL)

        return OAuthStartResult(
            message: "Browser opened for \(platform.rawValue.capitalized) OAuth. After consent, copy redirected URL and paste it in OmniPostD.",
            requiresCallbackPaste: true,
            pending: OAuthPending(provider: provider, state: state, codeVerifier: codeVerifier)
        )
    }

    func finishConnection(platform: PlatformID, callbackURLString: String, pending: OAuthPending) async throws -> ConnectedProfile {
        guard let callbackURL = URL(string: callbackURLString), let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            throw StandaloneOAuthError.invalidCallback
        }
        let params = Dictionary(uniqueKeysWithValues: components.queryItems?.map { ($0.name, $0.value ?? "") } ?? [])
        if let returnedState = params["state"], returnedState != pending.state {
            throw StandaloneOAuthError.stateMismatch
        }
        guard let code = params["code"], !code.isEmpty else {
            throw StandaloneOAuthError.missingCode
        }

        let creds = try credentials(for: pending.provider)
        let token = try await exchangeCode(provider: pending.provider, creds: creds, code: code, codeVerifier: pending.codeVerifier)
        let profile = try await fetchProfile(provider: pending.provider, accessToken: token)

        return ConnectedProfile(
            accountID: profile.accountID,
            accountName: profile.accountName,
            platform: platform
        )
    }

    private func provider(for platform: PlatformID) -> OAuthProvider? {
        switch platform {
        case .facebook: return .facebook
        case .twitter: return .twitter
        case .youtube: return .google
        case .reddit: return .reddit
        case .linkedin: return .linkedin
        case .pinterest: return .pinterest
        case .tiktok: return .tiktok
        case .snapchat: return .snapchat
        default: return nil
        }
    }

    private func credentialFileURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("OmniPostD", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("oauth_credentials.json")
    }

    private func loadCredentialFile() throws -> OAuthCredentialFile {
        let fileURL = credentialFileURL()
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let template = """
            {
              "facebook": {"clientID":"", "clientSecret":""},
              "twitter": {"clientID":"", "clientSecret":""},
              "google": {"clientID":"", "clientSecret":""},
              "reddit": {"clientID":"", "clientSecret":""},
              "linkedin": {"clientID":"", "clientSecret":""},
              "pinterest": {"clientID":"", "clientSecret":""},
              "tiktok": {"clientID":"", "clientSecret":""},
              "snapchat": {"clientID":"", "clientSecret":""}
            }
            """
            try? template.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(OAuthCredentialFile.self, from: data)
    }

    private func credentials(for provider: OAuthProvider) throws -> OAuthClientCredentials {
        let config = try loadCredentialFile()
        let creds: OAuthClientCredentials?

        switch provider {
        case .facebook: creds = config.facebook
        case .twitter: creds = config.twitter
        case .google: creds = config.google
        case .reddit: creds = config.reddit
        case .linkedin: creds = config.linkedin
        case .pinterest: creds = config.pinterest
        case .tiktok: creds = config.tiktok
        case .snapchat: creds = config.snapchat
        }

        guard let found = creds, !found.clientID.isEmpty else {
            throw StandaloneOAuthError.missingCredentials(provider.rawValue)
        }
        return found
    }

    private func authorizationURL(provider: OAuthProvider, creds: OAuthClientCredentials, state: String, codeChallenge: String?) -> URL {
        var components = URLComponents()

        switch provider {
        case .facebook:
            components.scheme = "https"
            components.host = "www.facebook.com"
            components.path = "/v18.0/dialog/oauth"
        case .twitter:
            components.scheme = "https"
            components.host = "twitter.com"
            components.path = "/i/oauth2/authorize"
        case .google:
            components.scheme = "https"
            components.host = "accounts.google.com"
            components.path = "/o/oauth2/v2/auth"
        case .reddit:
            components.scheme = "https"
            components.host = "www.reddit.com"
            components.path = "/api/v1/authorize"
        case .linkedin:
            components.scheme = "https"
            components.host = "www.linkedin.com"
            components.path = "/oauth/v2/authorization"
        case .pinterest:
            components.scheme = "https"
            components.host = "www.pinterest.com"
            components.path = "/oauth/"
        case .tiktok:
            components.scheme = "https"
            components.host = "www.tiktok.com"
            components.path = "/v2/auth/authorize/"
        case .snapchat:
            components.scheme = "https"
            components.host = "accounts.snapchat.com"
            components.path = "/accounts/oauth2/auth"
        }

        var query: [URLQueryItem] = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: creds.clientID),
            URLQueryItem(name: "redirect_uri", value: callbackURI),
            URLQueryItem(name: "state", value: state),
        ]

        switch provider {
        case .facebook:
            query.append(URLQueryItem(name: "scope", value: "pages_manage_posts,pages_read_engagement,instagram_basic,instagram_content_publish"))
        case .twitter:
            query.append(URLQueryItem(name: "scope", value: "tweet.read tweet.write users.read offline.access"))
            query.append(URLQueryItem(name: "code_challenge", value: codeChallenge))
            query.append(URLQueryItem(name: "code_challenge_method", value: "S256"))
        case .google:
            query.append(URLQueryItem(name: "scope", value: "https://www.googleapis.com/auth/youtube.upload https://www.googleapis.com/auth/youtube"))
            query.append(URLQueryItem(name: "access_type", value: "offline"))
            query.append(URLQueryItem(name: "prompt", value: "consent"))
        case .reddit:
            query.append(URLQueryItem(name: "scope", value: "submit read account"))
            query.append(URLQueryItem(name: "duration", value: "permanent"))
        case .linkedin:
            query.append(URLQueryItem(name: "scope", value: "r_liteprofile w_member_social"))
        case .pinterest:
            query.append(URLQueryItem(name: "scope", value: "boards:read boards:write pins:read pins:write"))
        case .tiktok:
            query.append(URLQueryItem(name: "scope", value: "user.info.basic,video.upload,video.publish"))
        case .snapchat:
            query.append(URLQueryItem(name: "scope", value: "snapchat-id user.display_name"))
        }

        components.queryItems = query
        return components.url!
    }

    private func exchangeCode(provider: OAuthProvider, creds: OAuthClientCredentials, code: String, codeVerifier: String?) async throws -> String {
        let tokenURL: URL
        switch provider {
        case .facebook: tokenURL = URL(string: "https://graph.facebook.com/v18.0/oauth/access_token")!
        case .twitter: tokenURL = URL(string: "https://api.twitter.com/2/oauth2/token")!
        case .google: tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
        case .reddit: tokenURL = URL(string: "https://www.reddit.com/api/v1/access_token")!
        case .linkedin: tokenURL = URL(string: "https://www.linkedin.com/oauth/v2/accessToken")!
        case .pinterest: tokenURL = URL(string: "https://api.pinterest.com/v5/oauth/token")!
        case .tiktok: tokenURL = URL(string: "https://open.tiktokapis.com/v2/oauth/token/")!
        case .snapchat: tokenURL = URL(string: "https://accounts.snapchat.com/accounts/oauth2/token")!
        }

        var params: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": callbackURI,
        ]

        switch provider {
        case .twitter:
            params["client_id"] = creds.clientID
            params["client_secret"] = creds.clientSecret
            params["code_verifier"] = codeVerifier ?? ""
        case .reddit, .pinterest:
            break
        default:
            params["client_id"] = creds.clientID
            params["client_secret"] = creds.clientSecret
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        if provider == .reddit || provider == .pinterest {
            let raw = "\(creds.clientID):\(creds.clientSecret)"
            let b64 = Data(raw.utf8).base64EncodedString()
            request.setValue("Basic \(b64)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = formURLEncoded(params).data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw StandaloneOAuthError.tokenExchangeFailed(String(data: data, encoding: .utf8) ?? "unknown")
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let accessToken = json["access_token"] as? String,
            !accessToken.isEmpty
        else {
            throw StandaloneOAuthError.tokenExchangeFailed("missing access_token")
        }

        return accessToken
    }

    private func fetchProfile(provider: OAuthProvider, accessToken: String) async throws -> (accountID: String, accountName: String) {
        let url: URL
        switch provider {
        case .facebook: url = URL(string: "https://graph.facebook.com/v18.0/me/accounts")!
        case .twitter: url = URL(string: "https://api.twitter.com/2/users/me")!
        case .google: url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
        case .reddit: url = URL(string: "https://oauth.reddit.com/api/v1/me")!
        case .linkedin: url = URL(string: "https://api.linkedin.com/v2/me")!
        case .pinterest: url = URL(string: "https://api.pinterest.com/v5/user_account")!
        case .tiktok: url = URL(string: "https://open.tiktokapis.com/v2/user/info/")!
        case .snapchat: url = URL(string: "https://adsapi.snapchat.com/v1/me")!
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw StandaloneOAuthError.profileFetchFailed(String(data: data, encoding: .utf8) ?? "unknown")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            throw StandaloneOAuthError.profileFetchFailed("invalid profile response")
        }

        switch provider {
        case .facebook:
            if
                let dict = json as? [String: Any],
                let dataRows = dict["data"] as? [[String: Any]],
                let first = dataRows.first,
                let id = first["id"] as? String,
                let name = first["name"] as? String
            {
                return (id, name)
            }
            return (UUID().uuidString, "Facebook User")
        case .twitter:
            if let dict = json as? [String: Any], let dataRow = dict["data"] as? [String: Any] {
                return ((dataRow["id"] as? String) ?? UUID().uuidString, (dataRow["username"] as? String) ?? "Twitter User")
            }
        case .google:
            if let dict = json as? [String: Any] {
                return ((dict["id"] as? String) ?? UUID().uuidString, (dict["name"] as? String) ?? "Google User")
            }
        case .reddit:
            if let dict = json as? [String: Any], let name = dict["name"] as? String {
                return (name, name)
            }
        case .linkedin:
            if let dict = json as? [String: Any] {
                let first = (dict["localizedFirstName"] as? String) ?? ""
                let last = (dict["localizedLastName"] as? String) ?? ""
                let name = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
                return ((dict["id"] as? String) ?? UUID().uuidString, name.isEmpty ? "LinkedIn User" : name)
            }
        case .pinterest:
            if let dict = json as? [String: Any] {
                return ((dict["id"] as? String) ?? UUID().uuidString, (dict["username"] as? String) ?? "Pinterest User")
            }
        case .tiktok:
            if
                let dict = json as? [String: Any],
                let dataObj = dict["data"] as? [String: Any],
                let userObj = dataObj["user"] as? [String: Any]
            {
                return ((userObj["open_id"] as? String) ?? UUID().uuidString, (userObj["display_name"] as? String) ?? "TikTok User")
            }
        case .snapchat:
            if
                let dict = json as? [String: Any],
                let me = dict["me"] as? [String: Any]
            {
                return ((me["id"] as? String) ?? UUID().uuidString, (me["display_name"] as? String) ?? "Snapchat User")
            }
        }

        return (UUID().uuidString, "Connected Account")
    }

    private func randomURLSafe(length: Int) -> String {
        let chars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return String((0..<length).map { _ in chars.randomElement()! })
    }

    private func sha256Base64URL(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        let data = Data(digest)
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func formURLEncoded(_ params: [String: String]) -> String {
        params
            .map { key, value in
                "\(percentEncode(key))=\(percentEncode(value))"
            }
            .sorted()
            .joined(separator: "&")
    }

    private func percentEncode(_ string: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}
