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
    var phone: String?
    var description: String?
    var createdAt: Date
    var lastLogin: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case role
        case biodata
        case phone
        case description
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

struct VendorCatalog: Identifiable, Codable {
    var id: String
    var vendorId: String
    var catalogId: String
    var name: String
    var description: String
    var price: Int
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
    case cancelled
}

struct Invoice: Identifiable, Codable {
    var id: String
    var eventId: String
    var vendorId: String
    var eventTitle: String
    var vendorName: String
    var catalogItemName: String
    var amount: Int
    var quantity: Int
    var status: InvoiceStatus
    var dueDate: Date
    var createdAt: Date
    var paidAt: Date?
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case vendorId = "vendor_id"
        case eventTitle = "event_title"
        case vendorName = "vendor_name"
        case catalogItemName = "catalog_item_name"
        case amount
        case quantity
        case status
        case dueDate = "due_date"
        case createdAt = "created_at"
        case paidAt = "paid_at"
        case notes
    }
}

struct EventVendorItem: Identifiable, Codable {
    var id: String
    var eventId: String
    var vendorId: String
    var catalogItemId: String
    var vendorName: String
    var itemName: String
    var itemPrice: Int
    var quantity: Int
    var eventTitle: String
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case vendorId = "vendor_id"
        case catalogItemId = "catalog_item_id"
        case vendorName = "vendor_name"
        case itemName = "item_name"
        case itemPrice = "item_price"
        case quantity
        case eventTitle = "event_title"
        case createdAt = "created_at"
    }
}
