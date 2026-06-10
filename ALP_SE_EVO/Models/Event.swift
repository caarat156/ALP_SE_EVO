import Foundation

enum EventStatus: String, Codable {
    case upcoming
    case ongoing
    case completed
    case cancelled
}

struct Event: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var eventDate: Date
    var location: String
    var quota: Int
    var registeredCount: Int
    var status: EventStatus
    var createdBy: String // Admin ID
    var createdAt: Date
    var vendorId: String? = nil // Selected Vendor ID
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case eventDate = "event_date"
        case location
        case quota
        case registeredCount = "registered_count"
        case status
        case createdBy = "created_by"
        case createdAt = "created_at"
        case vendorId = "vendor_id"
    }
}

struct EventRecap: Codable {
    let eventId: String
    let title: String
    let attendance: [String]
    let feedbackCount: Int
    let averageRating: Double
    let vendorList: [String]
    
    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case title
        case attendance
        case feedbackCount = "feedback_count"
        case averageRating = "average_rating"
        case vendorList = "vendor_list"
    }
}
