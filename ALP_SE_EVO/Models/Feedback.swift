import Foundation

struct Feedback: Identifiable, Codable {
    let id: String
    let eventId: String
    let pesertaId: String
    let targetId: String // Can be panitia ID for feedback about panitia
    var rating: Int // 1-5
    var comment: String
    var type: String // "panitia" or "vendor"
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case pesertaId = "peserta_id"
        case targetId = "target_id"
        case rating
        case comment
        case type
        case createdAt = "created_at"
    }
}

struct VendorReview: Identifiable, Codable {
    let id: String
    let vendorId: String
    let panitiaId: String
    let eventId: String
    var rating: Int // 1-5
    var comment: String
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vendorId = "vendor_id"
        case panitiaId = "panitia_id"
        case eventId = "event_id"
        case rating
        case comment
        case createdAt = "created_at"
    }
}

struct FormField: Identifiable, Codable {
    let id: String
    var fieldType: String // "text", "number", "date", "selection"
    var label: String
    var isRequired: Bool
    var options: [String]? // For selection type
    
    enum CodingKeys: String, CodingKey {
        case id
        case fieldType = "field_type"
        case label
        case isRequired = "is_required"
        case options
    }
}

struct EventForm: Identifiable, Codable {
    let id: String
    let eventId: String
    var title: String
    var fields: [FormField]
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case title
        case fields
        case createdAt = "created_at"
    }
}

struct FormResponse: Identifiable, Codable {
    let id: String
    let formId: String
    let pesertaId: String
    var responses: [String: String]
    var submittedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case formId = "form_id"
        case pesertaId = "peserta_id"
        case responses
        case submittedAt = "submitted_at"
    }
}
