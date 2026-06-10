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
    var createdBy: String
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, location, quota, status
        case eventDate = "event_date"
        case registeredCount = "registered_count"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

let dict: [String: Any] = [
    "id": "event1",
    "title": "Freshmen Welcoming 2026",
    "description": "Desc",
    "event_date": Date().timeIntervalSince1970,
    "location": "Loc",
    "quota": 500,
    "registered_count": 0,
    "status": "upcoming",
    "created_by": "panitia123",
    "created_at": Date().timeIntervalSince1970
]

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970
do {
    let jsonData = try JSONSerialization.data(withJSONObject: dict)
    let event = try decoder.decode(Event.self, from: jsonData)
    print("Success: \(event.title)")
} catch {
    print("Decode Error: \(error)")
}
