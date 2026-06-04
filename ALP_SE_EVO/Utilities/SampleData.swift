import Foundation

// MARK: - Sample Data for Testing

struct SampleData {
    static let samplePeserta = User(
        id: "peserta123",
        email: "peserta@evo.com",
        name: "John Doe",
        role: .peserta,
        createdAt: Date()
    )
    
    static let samplePanitia = User(
        id: "panitia123",
        email: "panitia@evo.com",
        name: "Committee Member",
        role: .panitia,
        createdAt: Date()
    )
    
    static let sampleVendor = User(
        id: "vendor123",
        email: "vendor@evo.com",
        name: "Vendor Company",
        role: .vendor,
        createdAt: Date()
    )
    
    static let sampleAdmin = User(
        id: "admin123",
        email: "admin@evo.com",
        name: "Administrator",
        role: .admin,
        createdAt: Date()
    )
    
    // Sample Events
    static let sampleEvent1 = Event(
        id: "event1",
        title: "Freshmen Welcoming 2026",
        description: "A welcoming event for new students at Ciputra University. Join us for an exciting day with activities, talks from senior students, and networking opportunities.",
        eventDate: Date().addingTimeInterval(-86400 * 2), // 2 days ago
        location: "Ciputra University Auditorium",
        quota: 500,
        registeredCount: 245,
        status: .completed,
        createdBy: "panitia123",
        createdAt: Date()
    )
    
    static let sampleEvent2 = Event(
        id: "event2",
        title: "Annual Tech Conference 2026",
        description: "A conference featuring talks from industry leaders about the latest in software engineering and technology trends.",
        eventDate: Date().addingTimeInterval(86400 * 10), // 10 days from now
        location: "Grand Ballroom, Jakarta",
        quota: 1000,
        registeredCount: 567,
        status: .upcoming,
        createdBy: "panitia123",
        createdAt: Date()
    )
    
    static let sampleEvent3 = Event(
        id: "event3",
        title: "Career Fair 2026",
        description: "Meet with leading companies and explore career opportunities in technology and business sectors.",
        eventDate: Date().addingTimeInterval(86400 * 15), // 15 days from now
        location: "Exhibition Center",
        quota: 300,
        registeredCount: 289,
        status: .ongoing,
        createdBy: "panitia123",
        createdAt: Date()
    )
    
    static let sampleEvents = [sampleEvent1, sampleEvent2, sampleEvent3]
    
    // Sample Tickets
    static let sampleTicket1 = Ticket(
        id: "ticket1",
        eventId: "event1",
        eventTitle: sampleEvent1.title,
        pesertaId: "peserta123",
        status: .used,
        encryptedData: "dGlja2tldDE6ZXZlbnQxOnBlc2VydGExMjM6MTcxNzMyMzMzMw==",
        createdAt: Date()
    )
    
    static let sampleTicket2 = Ticket(
        id: "ticket2",
        eventId: "event2",
        eventTitle: sampleEvent2.title,
        pesertaId: "peserta123",
        status: .active,
        encryptedData: "dGlja2tldDI6ZXZlbnQyOnBlc2VydGExMjM6MTcxNzMyNDQzMw==",
        createdAt: Date()
    )
    
    static let sampleTickets = [sampleTicket1, sampleTicket2]
    
    // Sample Vendors
    static let sampleVendor1 = User(
        id: "vendor1",
        email: "catering@delights.com",
        name: "Catering Delights",
        role: .vendor,
        phone: "+62812345678",
        createdAt: Date()
    )
    
    static let sampleVendor2 = User(
        id: "vendor2",
        email: "sound@premium.com",
        name: "Premium Sound & Lights",
        role: .vendor,
        phone: "+62887654321",
        createdAt: Date()
    )
    
    static let sampleVendors = [sampleVendor1, sampleVendor2]
    
    // Sample Catalog Items
    static let sampleCatalog1 = VendorCatalog(
        id: "catalog1",
        vendorId: "vendor1",
        catalogId: "pkg1",
        name: "Standard Catering Package",
        description: "Buffet with local and international cuisine for up to 500 persons",
        price: 50000000,
        quantity: 5,
        createdAt: Date()
    )
    
    static let sampleCatalog2 = VendorCatalog(
        id: "catalog2",
        vendorId: "vendor1",
        catalogId: "pkg2",
        name: "Premium Catering Package",
        description: "Premium buffet with fine dining options for up to 500 persons",
        price: 75000000,
        quantity: 3,
        createdAt: Date()
    )
    
    static let sampleCatalogItems = [sampleCatalog1, sampleCatalog2]
    
    // Sample Invoices
    static let sampleInvoice1 = Invoice(
        id: "inv1",
        eventId: "event1",
        vendorId: "vendor1",
        eventTitle: sampleEvent1.title,
        vendorName: sampleVendor1.name,
        catalogItemName: sampleCatalog1.name,
        amount: 50000000,
        quantity: 1,
        status: .unpaid,
        dueDate: Date().addingTimeInterval(86400 * 7),
        createdAt: Date(),
        notes: "Catering untuk Freshmen Welcoming 2026"
    )
    
    static let sampleInvoice2 = Invoice(
        id: "inv2",
        eventId: "event2",
        vendorId: "vendor2",
        eventTitle: sampleEvent2.title,
        vendorName: sampleVendor2.name,
        catalogItemName: "Sound System Package",
        amount: 15000000,
        quantity: 1,
        status: .paid,
        dueDate: Date().addingTimeInterval(-86400),
        createdAt: Date(),
        paidAt: Date().addingTimeInterval(-172800),
        notes: "Sound & Lighting untuk Tech Conference"
    )
    
    static let sampleInvoices = [sampleInvoice1, sampleInvoice2]
    
    // Sample Event Vendor Items (linking vendor products to events)
    static let sampleEventVendorItem1 = EventVendorItem(
        id: "evi1",
        eventId: "event1",
        vendorId: "vendor1",
        catalogItemId: "catalog1",
        vendorName: sampleVendor1.name,
        itemName: sampleCatalog1.name,
        itemPrice: sampleCatalog1.price,
        quantity: 1,
        eventTitle: sampleEvent1.title,
        createdAt: Date()
    )
    
    static let sampleEventVendorItem2 = EventVendorItem(
        id: "evi2",
        eventId: "event2",
        vendorId: "vendor2",
        catalogItemId: "catalog2",
        vendorName: sampleVendor2.name,
        itemName: sampleCatalog2.name,
        itemPrice: sampleCatalog2.price,
        quantity: 1,
        eventTitle: sampleEvent2.title,
        createdAt: Date()
    )
    
    static let sampleEventVendorItems = [sampleEventVendorItem1, sampleEventVendorItem2]
    
    // Print all sample data info
    static func printSampleDataInfo() {
        print("""
        === SAMPLE DATA INFO ===
        
        Users:
        - Peserta: \(samplePeserta.email)
        - Panitia: \(samplePanitia.email)
        - Vendor: \(sampleVendor.email)
        - Admin: \(sampleAdmin.email)
        
        Events: \(sampleEvents.count)
        - \(sampleEvent1.title)
        - \(sampleEvent2.title)
        - \(sampleEvent3.title)
        
        Tickets: \(sampleTickets.count)
        Vendors: \(sampleVendors.count)
        Catalog Items: \(sampleCatalogItems.count)
        Invoices: \(sampleInvoices.count)
        Event-Vendor Items: \(sampleEventVendorItems.count)
        """)
    }
}

// MARK: - Mock Firebase Service for Testing (Without Real Firebase)

class MockFirebaseService {
    static let shared = MockFirebaseService()
    
    private var users: [String: User] = [:]
    private var events: [String: Event] = [:]
    private var tickets: [String: Ticket] = [:]
    private var feedback: [String: Feedback] = [:]
    private var vendors: [String: User] = [:]
    
    init() {
        // Initialize with sample data
        users[SampleData.samplePeserta.id] = SampleData.samplePeserta
        users[SampleData.samplePanitia.id] = SampleData.samplePanitia
        users[SampleData.sampleVendor.id] = SampleData.sampleVendor
        users[SampleData.sampleAdmin.id] = SampleData.sampleAdmin
        
        for event in SampleData.sampleEvents {
            events[event.id] = event
        }
        
        for vendor in SampleData.sampleVendors {
            vendors[vendor.id] = vendor
        }
    }
    
    // MARK: - Mock User Operations
    
    func getUser(uid: String, completion: @escaping (User?, String?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let user = self.users[uid] {
                completion(user, nil)
            } else {
                completion(nil, "User not found")
            }
        }
    }
    
    func saveUser(_ user: User, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.users[user.id] = user
            completion(true, nil)
        }
    }
    
    // MARK: - Mock Event Operations
    
    func createEvent(_ event: Event, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.events[event.id] = event
            completion(true, nil)
        }
    }
    
    func getAllEvents(completion: @escaping ([Event]?, String?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion(Array(self.events.values), nil)
        }
    }
    
    func getEvent(_ eventId: String, completion: @escaping (Event?, String?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let event = self.events[eventId] {
                completion(event, nil)
            } else {
                completion(nil, "Event not found")
            }
        }
    }
    
    // MARK: - Mock Vendor Operations
    
    func getAllVendors(completion: @escaping ([User]?, String?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion(Array(self.vendors.values), nil)
        }
    }
    
    func addUser(_ vendor: User, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.vendors[vendor.id] = vendor
            completion(true, nil)
        }
    }
    
    // Add more mock methods as needed
}
