import Foundation

enum UserRole: String, Codable {
    case peserta
    case panitia
    case vendor
    case admin
}

struct User: Identifiable, Codable {
    var id: String
    let email: String
    var name: String
    let role: UserRole
    var biodata: String?
    var createdAt: Date
    var lastLogin: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case role
        case biodata
        case createdAt = "created_at"
        case lastLogin = "last_login"
    }
}

struct AuthResponse: Codable {
    let uid: String
    let email: String
    let displayName: String?
    let role: String
}
