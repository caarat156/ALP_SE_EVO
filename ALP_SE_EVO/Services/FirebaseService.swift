import Foundation
import Firebase
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    
    // MARK: - Shared Encoder/Decoder
    
    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        return e
    }
    
    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }
    
    /// Encode a Codable to [String: Any] for Firestore
    private func encodeToDict<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try encoder.encode(value)
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        guard let dict = jsonObject as? [String: Any] else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize data"])
        }
        return dict
    }
    
    /// Decode a Firestore document dict to a Codable
    private func decodeFromDict<T: Decodable>(_ type: T.Type, dict: [String: Any]) throws -> T {
        // Convert Firestore Timestamps to epoch seconds so JSONDecoder can handle them
        let converted = convertTimestamps(dict)
        let jsonData = try JSONSerialization.data(withJSONObject: converted)
        return try decoder.decode(type, from: jsonData)
    }
    
    /// Recursively convert Firestore Timestamp objects to epoch Double values
    private func convertTimestamps(_ dict: [String: Any]) -> [String: Any] {
        var result = [String: Any]()
        for (key, value) in dict {
            if let timestamp = value as? Timestamp {
                result[key] = timestamp.dateValue().timeIntervalSince1970
            } else if let subDict = value as? [String: Any] {
                result[key] = convertTimestamps(subDict)
            } else if let arr = value as? [[String: Any]] {
                result[key] = arr.map { convertTimestamps($0) }
            } else {
                result[key] = value
            }
        }
        return result
    }
    
    // MARK: - User Operations
    
    func getUser(uid: String, completion: @escaping (User?, String?) -> Void) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            guard let data = snapshot?.data() else {
                completion(nil, "No user data found")
                return
            }
            do {
                let user = try self?.decodeFromDict(User.self, dict: data)
                completion(user, nil)
            } catch {
                completion(nil, error.localizedDescription)
            }
        }
    }
    
    func getAllUsers(completion: @escaping ([User]?, String?) -> Void) {
        db.collection("users").getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            var users: [User] = []
            for document in snapshot?.documents ?? [] {
                do {
                    if let user = try self?.decodeFromDict(User.self, dict: document.data()) {
                        users.append(user)
                    }
                } catch {
                    print("Error decoding user: \(error)")
                }
            }
            completion(users, nil)
        }
    }
    
    func saveUser(_ user: User, completion: @escaping (Bool, String?) -> Void) {
        do {
            let jsonDict = try encodeToDict(user)
            db.collection("users").document(user.id).setData(jsonDict) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }
    
    func deleteUser(userId: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("users").document(userId).delete { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
    
    // MARK: - Event Operations
    
    func createEvent(_ event: Event, completion: @escaping (Bool, String?) -> Void) {
        do {
            let jsonDict = try encodeToDict(event)
            db.collection("events").document(event.id).setData(jsonDict) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }
    
    func getEvent(_ eventId: String, completion: @escaping (Event?, String?) -> Void) {
        db.collection("events").document(eventId).getDocument { [weak self] snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            guard let data = snapshot?.data() else {
                completion(nil, "No event data found")
                return
            }
            do {
                let event = try self?.decodeFromDict(Event.self, dict: data)
                completion(event, nil)
            } catch {
                completion(nil, error.localizedDescription)
            }
        }
    }
    
    func getAllEvents(completion: @escaping ([Event]?, String?) -> Void) {
        db.collection("events").getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            var events: [Event] = []
            for document in snapshot?.documents ?? [] {
                do {
                    if let event = try self?.decodeFromDict(Event.self, dict: document.data()) {
                        events.append(event)
                    }
                } catch {
                    print("Error decoding event: \(error)")
                }
            }
            completion(events, nil)
        }
    }
    
    func getPanitiaEvents(panitiaId: String, completion: @escaping ([Event]?, String?) -> Void) {
        db.collection("events").whereField("created_by", isEqualTo: panitiaId).getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            var events: [Event] = []
            for document in snapshot?.documents ?? [] {
                do {
                    if let event = try self?.decodeFromDict(Event.self, dict: document.data()) {
                        events.append(event)
                    }
                } catch {
                    print("Error decoding event: \(error)")
                }
            }
            completion(events, nil)
        }
    }
    
    // MARK: - Ticket Operations
    
    func seedTicket(_ ticket: Ticket, completion: @escaping (Bool, String?) -> Void) {
        do {
            let jsonDict = try encodeToDict(ticket)
            db.collection("tickets").document(ticket.id).setData(jsonDict) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }
    
    func registerEventForPeserta(pesertaId: String, eventId: String, eventTitle: String, completion: @escaping (Bool, String?) -> Void) {
        let ticketId = UUID().uuidString
        let ticket = Ticket(
            id: ticketId,
            eventId: eventId,
            eventTitle: eventTitle,
            pesertaId: pesertaId,
            status: .active,
            encryptedData: generateEncryptedQRCode(ticketId: ticketId, eventId: eventId, pesertaId: pesertaId),
            createdAt: Date()
        )
        
        do {
            let jsonDict = try encodeToDict(ticket)
            db.collection("tickets").document(ticketId).setData(jsonDict) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    // Update event registered count
                    self.updateEventRegisteredCount(eventId: eventId, increment: true)
                    completion(true, nil)
                }
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }
    
    func getTickets(pesertaId: String, completion: @escaping ([Ticket]?, String?) -> Void) {
        db.collection("tickets").whereField("peserta_id", isEqualTo: pesertaId).getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            var tickets: [Ticket] = []
            for document in snapshot?.documents ?? [] {
                do {
                    if let ticket = try self?.decodeFromDict(Ticket.self, dict: document.data()) {
                        tickets.append(ticket)
                    }
                } catch {
                    print("Error decoding ticket: \(error)")
                }
            }
            completion(tickets, nil)
        }
    }
    
    func getRegisteredEvents(pesertaId: String, completion: @escaping ([Event]?, String?) -> Void) {
        db.collection("tickets").whereField("peserta_id", isEqualTo: pesertaId).getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            var events: [Event] = []
            let dispatchGroup = DispatchGroup()
            for document in snapshot?.documents ?? [] {
                if let eventId = document.data()["event_id"] as? String {
                    dispatchGroup.enter()
                    self?.getEvent(eventId) { event, _ in
                        if let event = event {
                            events.append(event)
                        }
                        dispatchGroup.leave()
                    }
                }
            }
            dispatchGroup.notify(queue: .main) {
                completion(events, nil)
            }
        }
    }
    
    // MARK: - Feedback Operations
    
    func saveFeedback(_ feedback: Feedback, completion: @escaping (Bool, String?) -> Void) {
        do {
            let jsonDict = try encodeToDict(feedback)
            db.collection("feedback").document(feedback.id).setData(jsonDict) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }
    
    func getFeedback(eventId: String, targetId: String, completion: @escaping ([Feedback]?, String?) -> Void) {
        db.collection("feedback")
            .whereField("event_id", isEqualTo: eventId)
            .whereField("target_id", isEqualTo: targetId)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(nil, error.localizedDescription)
                    return
                }
                var feedback: [Feedback] = []
                for document in snapshot?.documents ?? [] {
                    do {
                        if let fb = try self?.decodeFromDict(Feedback.self, dict: document.data()) {
                            feedback.append(fb)
                        }
                    } catch {
                        print("Error decoding feedback: \(error)")
                    }
                }
                completion(feedback, nil)
            }
    }
    
    // MARK: - Vendor Operations
    
    func getAllVendors(completion: @escaping ([User]?, String?) -> Void) {
        db.collection("users").whereField("role", isEqualTo: "vendor").getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            var vendors: [User] = []
            for document in snapshot?.documents ?? [] {
                do {
                    if let vendor = try self?.decodeFromDict(User.self, dict: document.data()) {
                        vendors.append(vendor)
                    }
                } catch {
                    print("Error decoding vendor: \(error)")
                }
            }
            completion(vendors, nil)
        }
    }
    
    func deleteVendorUser(vendorId: String, completion: @escaping (Bool, String?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var hasError = false
        var errorMessage: String?
        
        // 1. Delete all catalog items for this vendor
        dispatchGroup.enter()
        db.collection("catalog").whereField("vendor_id", isEqualTo: vendorId).getDocuments { [weak self] snapshot, error in
            if let error = error {
                hasError = true
                errorMessage = error.localizedDescription
                dispatchGroup.leave()
                return
            }
            guard let docs = snapshot?.documents, !docs.isEmpty else {
                dispatchGroup.leave()
                return
            }
            let batch = self?.db.batch()
            for document in docs {
                batch?.deleteDocument(document.reference)
            }
            batch?.commit { error in
                if let error = error {
                    hasError = true
                    errorMessage = error.localizedDescription
                }
                dispatchGroup.leave()
            }
        }
        
        // 2. Delete the vendor itself
        dispatchGroup.enter()
        db.collection("users").document(vendorId).delete { error in
            if let error = error {
                hasError = true
                errorMessage = error.localizedDescription
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            if hasError {
                completion(false, errorMessage)
            } else {
                completion(true, nil)
            }
        }
    }
    
    // MARK: - Catalog Operations
    
    func addCatalogItem(_ catalog: VendorCatalog, completion: @escaping (Bool, String?) -> Void) {
        do {
            let jsonDict = try encodeToDict(catalog)
            db.collection("catalog").document(catalog.id).setData(jsonDict) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }
    
    func getVendorCatalog(vendorId: String, completion: @escaping ([VendorCatalog]?, String?) -> Void) {
        db.collection("catalog").whereField("vendor_id", isEqualTo: vendorId).getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            var items: [VendorCatalog] = []
            for document in snapshot?.documents ?? [] {
                do {
                    if let item = try self?.decodeFromDict(VendorCatalog.self, dict: document.data()) {
                        items.append(item)
                    }
                } catch {
                    print("Error decoding catalog item: \(error)")
                }
            }
            completion(items, nil)
        }
    }
    
    func getAllCatalogItems(completion: @escaping ([VendorCatalog]?, String?) -> Void) {
        db.collection("catalog").getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            var items: [VendorCatalog] = []
            for document in snapshot?.documents ?? [] {
                do {
                    if let item = try self?.decodeFromDict(VendorCatalog.self, dict: document.data()) {
                        items.append(item)
                    }
                } catch {
                    print("Error decoding catalog item: \(error)")
                }
            }
            completion(items, nil)
        }
    }
    
    // MARK: - Event Vendor Items (linking vendor products to events)
    
    func saveEventVendorItem(_ item: EventVendorItem, completion: @escaping (Bool, String?) -> Void) {
        do {
            let jsonDict = try encodeToDict(item)
            db.collection("event_vendor_items").document(item.id).setData(jsonDict) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }
    
    func getEventVendorItems(eventId: String, completion: @escaping ([EventVendorItem]?, String?) -> Void) {
        db.collection("event_vendor_items").whereField("event_id", isEqualTo: eventId).getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            var items: [EventVendorItem] = []
            for document in snapshot?.documents ?? [] {
                do {
                    if let item = try self?.decodeFromDict(EventVendorItem.self, dict: document.data()) {
                        items.append(item)
                    }
                } catch {
                    print("Error decoding event vendor item: \(error)")
                }
            }
            completion(items, nil)
        }
    }
    
    func getVendorEventItems(vendorId: String, completion: @escaping ([EventVendorItem]?, String?) -> Void) {
        db.collection("event_vendor_items").whereField("vendor_id", isEqualTo: vendorId).getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            var items: [EventVendorItem] = []
            for document in snapshot?.documents ?? [] {
                do {
                    if let item = try self?.decodeFromDict(EventVendorItem.self, dict: document.data()) {
                        items.append(item)
                    }
                } catch {
                    print("Error decoding event vendor item: \(error)")
                }
            }
            completion(items, nil)
        }
    }
    
    // MARK: - Invoice Operations
    
    func getVendorInvoices(vendorId: String, completion: @escaping ([Invoice]?, String?) -> Void) {
        db.collection("invoices").whereField("vendor_id", isEqualTo: vendorId).getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            var invoices: [Invoice] = []
            for document in snapshot?.documents ?? [] {
                do {
                    if let invoice = try self?.decodeFromDict(Invoice.self, dict: document.data()) {
                        invoices.append(invoice)
                    }
                } catch {
                    print("Error decoding invoice: \(error)")
                }
            }
            completion(invoices, nil)
        }
    }
    
    func createInvoice(_ invoice: Invoice, completion: @escaping (Bool, String?) -> Void) {
        do {
            let jsonDict = try encodeToDict(invoice)
            db.collection("invoices").document(invoice.id).setData(jsonDict) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }
    
    // MARK: - Attendance Operations
    
    func recordAttendance(eventId: String, pesertaId: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("tickets")
            .whereField("event_id", isEqualTo: eventId)
            .whereField("peserta_id", isEqualTo: pesertaId)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                guard let document = snapshot?.documents.first else {
                    completion(false, "Ticket not found")
                    return
                }
                let ticketId = document.documentID
                self?.db.collection("tickets").document(ticketId).updateData([
                    "status": "used",
                    "used_at": Date().timeIntervalSince1970
                ]) { error in
                    if let error = error {
                        completion(false, error.localizedDescription)
                    } else {
                        completion(true, nil)
                    }
                }
            }
    }
    
    // MARK: - Event Recap Operations
    
    func getEventRecap(eventId: String, completion: @escaping (EventRecap?) -> Void) {
        var attendance: [String] = []
        var feedbackCount = 0
        var vendorList: [String] = []
        var averageRating = 0.0
        
        let dispatchGroup = DispatchGroup()
        
        // Get attendance
        dispatchGroup.enter()
        db.collection("tickets")
            .whereField("event_id", isEqualTo: eventId)
            .whereField("status", isEqualTo: "used")
            .getDocuments { snapshot, _ in
                attendance = snapshot?.documents.compactMap { $0.data()["peserta_id"] as? String } ?? []
                dispatchGroup.leave()
            }
        
        // Get feedback count and average rating
        dispatchGroup.enter()
        db.collection("feedback")
            .whereField("event_id", isEqualTo: eventId)
            .getDocuments { [weak self] snapshot, _ in
                let feedbacks = snapshot?.documents.compactMap { doc -> Feedback? in
                    do {
                        return try self?.decodeFromDict(Feedback.self, dict: doc.data())
                    } catch {
                        return nil
                    }
                } ?? []
                feedbackCount = feedbacks.count
                if !feedbacks.isEmpty {
                    averageRating = Double(feedbacks.map { $0.rating }.reduce(0, +)) / Double(feedbacks.count)
                }
                dispatchGroup.leave()
            }
        
        // Get event title
        var eventTitle = ""
        dispatchGroup.enter()
        db.collection("events").document(eventId).getDocument { snapshot, _ in
            eventTitle = snapshot?.data()?["title"] as? String ?? ""
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            let recap = EventRecap(
                eventId: eventId,
                title: eventTitle,
                attendance: attendance,
                feedbackCount: feedbackCount,
                averageRating: averageRating,
                vendorList: vendorList
            )
            completion(recap)
        }
    }
    
    // MARK: - Helper Functions
    
    private func updateEventRegisteredCount(eventId: String, increment: Bool) {
        db.collection("events").document(eventId).getDocument { [weak self] snapshot, _ in
            if let currentCount = snapshot?.data()?["registered_count"] as? Int {
                let newCount = increment ? currentCount + 1 : max(currentCount - 1, 0)
                self?.db.collection("events").document(eventId).updateData(["registered_count": newCount])
            }
        }
    }
    
    private func generateEncryptedQRCode(ticketId: String, eventId: String, pesertaId: String) -> String {
        let data = "\(ticketId)|\(eventId)|\(pesertaId)|\(Date().timeIntervalSince1970)"
        return data.base64Encoded() ?? data
    }
    
    // MARK: - Reset Operations
    
    func resetDatabase(completion: @escaping (Bool, String?) -> Void) {
        let collections = ["users", "events", "vendors", "tickets", "catalog", "invoices", "feedback", "event_vendor_items"]
        let dispatchGroup = DispatchGroup()
        var errorMessages: [String] = []
        
        for collectionName in collections {
            dispatchGroup.enter()
            db.collection(collectionName).getDocuments { [weak self] snapshot, error in
                if let error = error {
                    errorMessages.append("Failed to fetch \(collectionName): \(error.localizedDescription)")
                    dispatchGroup.leave()
                    return
                }
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    dispatchGroup.leave()
                    return
                }
                let batchGroup = DispatchGroup()
                for document in documents {
                    batchGroup.enter()
                    self?.db.collection(collectionName).document(document.documentID).delete { error in
                        if let error = error {
                            errorMessages.append("Failed to delete from \(collectionName): \(error.localizedDescription)")
                        }
                        batchGroup.leave()
                    }
                }
                batchGroup.notify(queue: .main) {
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if errorMessages.isEmpty {
                completion(true, nil)
            } else {
                completion(false, errorMessages.joined(separator: "\n"))
            }
        }
    }
}

extension String {
    func base64Encoded() -> String? {
        let data = self.data(using: .utf8)
        return data?.base64EncodedString()
    }
    
    func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
