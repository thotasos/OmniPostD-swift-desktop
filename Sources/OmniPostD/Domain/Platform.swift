import Foundation

enum PlatformID: String, CaseIterable, Codable, Identifiable {
    case facebook
    case instagram
    case twitter
    case youtube
    case linkedin
    case reddit
    case pinterest
    case tiktok
    case tumblr
    case snapchat
    case discord

    var id: String { rawValue }
}

enum ContentType: String, CaseIterable, Codable, Hashable {
    case text
    case image
    case video
    case link
    case article
}

struct PlatformProfile: Codable, Hashable, Identifiable {
    let id: PlatformID
    let name: String
    let characterLimit: Int
    let supportedContent: Set<ContentType>
}

enum PlatformCatalog {
    static let all: [PlatformProfile] = [
        PlatformProfile(id: .facebook, name: "Facebook", characterLimit: 63206, supportedContent: [.text, .image, .video, .link]),
        PlatformProfile(id: .instagram, name: "Instagram", characterLimit: 2200, supportedContent: [.text, .image, .video]),
        PlatformProfile(id: .twitter, name: "Twitter/X", characterLimit: 280, supportedContent: [.text, .image, .video, .link]),
        PlatformProfile(id: .youtube, name: "YouTube", characterLimit: 5000, supportedContent: [.video, .link]),
        PlatformProfile(id: .linkedin, name: "LinkedIn", characterLimit: 3000, supportedContent: [.text, .image, .video, .link, .article]),
        PlatformProfile(id: .reddit, name: "Reddit", characterLimit: 40000, supportedContent: [.text, .image, .video, .link]),
        PlatformProfile(id: .pinterest, name: "Pinterest", characterLimit: 500, supportedContent: [.text, .image, .video]),
        PlatformProfile(id: .tiktok, name: "TikTok", characterLimit: 2200, supportedContent: [.text, .video]),
        PlatformProfile(id: .tumblr, name: "Tumblr", characterLimit: 2000, supportedContent: [.text, .image, .video, .link]),
        PlatformProfile(id: .snapchat, name: "Snapchat", characterLimit: 2000, supportedContent: [.image, .video]),
        PlatformProfile(id: .discord, name: "Discord", characterLimit: 2000, supportedContent: [.text, .image, .link]),
    ]

    static func platform(id: PlatformID) -> PlatformProfile? {
        all.first { $0.id == id }
    }
}
