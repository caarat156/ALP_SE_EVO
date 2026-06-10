import Foundation

enum EventStatus: String, Codable {
    case upcoming, ongoing, completed, cancelled
}

struct Event: Codable {
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
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, location, quota, status
        case eventDate = "event_date"
        case registeredCount = "registered_count"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

let event = Event(id: "1", title: "Test", description: "Test", eventDate: Date(), location: "Loc", quota: 10, registeredCount: 0, status: .upcoming, createdBy: "admin", createdAt: Date())

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970
do {
    let data = try encoder.encode(event)
    let jsonObject = try JSONSerialization.jsonObject(with: data)
    print("Success: \(jsonObject)")
} catch {
    print("Error: \(error)")
}
