import Foundation

enum TicketStatus: String, Codable {
    case active
    case used
    case cancelled
}

struct Ticket: Identifiable, Codable {
    let id: String
    let eventId: String
    let pesertaId: String
    var status: TicketStatus
    var encryptedData: String // QR Code encrypted data
    let createdAt: Date
    var usedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case pesertaId = "peserta_id"
        case status
        case encryptedData = "encrypted_data"
        case createdAt = "created_at"
        case usedAt = "used_at"
    }
}

struct QRCodeData: Codable {
    let ticketId: String
    let eventId: String
    let pesertaId: String
    let timestamp: Date
    let checksum: String
}
