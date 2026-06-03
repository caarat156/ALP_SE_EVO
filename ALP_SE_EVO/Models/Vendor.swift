import Foundation

struct Vendor: Identifiable, Codable {
    let id: String
    var name: String
    var email: String
    var phone: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case createdAt = "created_at"
    }
}

struct VendorCatalog: Identifiable, Codable {
    let id: String
    let vendorId: String
    var catalogId: String
    var name: String
    var description: String?
    var price: Double
    var quantity: Int
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vendorId = "vendor_id"
        case catalogId = "catalog_id"
        case name
        case description
        case price
        case quantity
        case createdAt = "created_at"
    }
}

enum InvoiceStatus: String, Codable {
    case unpaid
    case paid
    case overdue
    case cancelled
}

struct Invoice: Identifiable, Codable {
    let id: String
    let eventId: String
    let vendorId: String
    var amount: Double
    var status: InvoiceStatus
    var dueDate: Date
    var createdAt: Date
    var paidAt: Date?
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case vendorId = "vendor_id"
        case amount
        case status
        case dueDate = "due_date"
        case createdAt = "created_at"
        case paidAt = "paid_at"
        case notes
    }
}
