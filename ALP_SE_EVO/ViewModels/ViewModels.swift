import Foundation

class NavigationManager: ObservableObject {
    @Published var currentTab = 0
    @Published var selectedEvent: Event?
    @Published var showingEventDetails = false
    @Published var showingQRScanner = false
}

class PesertaViewModel: ObservableObject {
    @Published var registeredEvents: [Event] = []
    @Published var tickets: [Ticket] = []
    @Published var feedbackForm: [Feedback] = []
    @Published var isLoading = false
    
    private let firebaseService = FirebaseService.shared
    
    func fetchRegisteredEvents(pesertaId: String) {
        isLoading = true
        firebaseService.getRegisteredEvents(pesertaId: pesertaId) { [weak self] events, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let events = events {
                    self?.registeredEvents = events
                }
            }
        }
    }
    
    func fetchTickets(pesertaId: String) {
        firebaseService.getTickets(pesertaId: pesertaId) { [weak self] tickets, error in
            DispatchQueue.main.async {
                if let tickets = tickets {
                    self?.tickets = tickets
                }
            }
        }
    }
    
    func registerEvent(pesertaId: String, eventId: String, completion: @escaping (Bool, String?) -> Void) {
        firebaseService.registerEventForPeserta(pesertaId: pesertaId, eventId: eventId) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.fetchRegisteredEvents(pesertaId: pesertaId)
                    self?.fetchTickets(pesertaId: pesertaId)
                }
                completion(success, error)
            }
        }
    }
    
    func submitFeedback(feedback: Feedback, completion: @escaping (Bool, String?) -> Void) {
        firebaseService.saveFeedback(feedback) { success, error in
            completion(success, error)
        }
    }
    
    func getEventTitle(for eventId: String) -> String {
        return registeredEvents.first(where: { $0.id == eventId })?.title ?? "Loading Event Info..."
    }
    
    func hasAttendedEvent(eventId: String) -> Bool {
        return tickets.contains(where: { $0.eventId == eventId && $0.status == .used })
    }
}

class PanitiaViewModel: ObservableObject {
    @Published var managedEvents: [Event] = []
    @Published var attendance: [String: [String]] = [:]
    @Published var isLoading = false
    @Published var eventMetrics: EventRecap?
    
    private let firebaseService = FirebaseService.shared
    
    func fetchManagedEvents(panitiaId: String) {
        isLoading = true
        firebaseService.getPanitiaEvents(panitiaId: panitiaId) { [weak self] events, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let events = events {
                    self?.managedEvents = events
                }
            }
        }
    }
    
    func createEvent(event: Event, completion: @escaping (Bool, String?) -> Void) {
        firebaseService.createEvent(event) { [weak self] success, error in
            if success {
                self?.fetchManagedEvents(panitiaId: event.createdBy)
            }
            completion(success, error)
        }
    }
    
    func getEventRecap(eventId: String, completion: @escaping (EventRecap?) -> Void) {
        firebaseService.getEventRecap(eventId: eventId) { recap in
            DispatchQueue.main.async {
                self.eventMetrics = recap
                completion(recap)
            }
        }
    }
    
    func recordAttendance(eventId: String, scannedCode: String, completion: @escaping (Bool) -> Void) {
        firebaseService.recordAttendance(eventId: eventId, scannedCode: scannedCode) { success, _ in
            completion(success)
        }
    }
}

class VendorViewModel: ObservableObject {
    @Published var catalogItems: [VendorCatalog] = []
    @Published var invoices: [Invoice] = []
    @Published var isLoading = false
    
    private let firebaseService = FirebaseService.shared
    
    func fetchCatalog(vendorId: String) {
        isLoading = true
        firebaseService.getVendorCatalog(vendorId: vendorId) { [weak self] items, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let items = items {
                    self?.catalogItems = items
                }
            }
        }
    }
    
    func addCatalogItem(catalog: VendorCatalog, completion: @escaping (Bool, String?) -> Void) {
        firebaseService.addCatalogItem(catalog) { [weak self] success, error in
            if success {
                self?.fetchCatalog(vendorId: catalog.vendorId)
            }
            completion(success, error)
        }
    }
    
    func fetchInvoices(vendorId: String) {
        firebaseService.getVendorInvoices(vendorId: vendorId) { [weak self] invoices, error in
            DispatchQueue.main.async {
                if let invoices = invoices {
                    self?.invoices = invoices
                }
            }
        }
    }
    
    func updateInvoiceStatus(invoiceId: String, vendorId: String, status: InvoiceStatus, completion: @escaping (Bool, String?) -> Void) {
        firebaseService.updateInvoiceStatus(invoiceId: invoiceId, status: status) { [weak self] success, error in
            if success {
                self?.fetchInvoices(vendorId: vendorId)
            }
            completion(success, error)
        }
    }
}

class AdminViewModel: ObservableObject {
    @Published var allVendors: [Vendor] = []
    @Published var allUsers: [User] = []
    @Published var allEvents: [Event] = []
    @Published var isLoading = false
    
    private let firebaseService = FirebaseService.shared
    
    func fetchAllVendors() {
        isLoading = true
        firebaseService.getAllVendors { [weak self] vendors, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let vendors = vendors {
                    self?.allVendors = vendors
                }
            }
        }
    }
    
    func addVendor(vendor: Vendor, completion: @escaping (Bool, String?) -> Void) {
        firebaseService.addVendor(vendor) { success, error in
            if success {
                self.fetchAllVendors()
            }
            completion(success, error)
        }
    }
    
    func fetchAllEvents() {
        firebaseService.getAllEvents { [weak self] events, error in
            DispatchQueue.main.async {
                if let events = events {
                    self?.allEvents = events
                }
            }
        }
    }
    
    func createGlobalEvent(event: Event, completion: @escaping (Bool, String?) -> Void) {
        firebaseService.createEvent(event) { [weak self] success, error in
            if success {
                self?.fetchAllEvents()
            }
            completion(success, error)
        }
    }
}
