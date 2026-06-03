import Foundation
import Firebase
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    
    // MARK: - User Operations
    
    func getUser(uid: String, completion: @escaping (User?, String?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(nil, "No user data found")
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let user = try JSONDecoder().decode(User.self, from: jsonData)
                completion(user, nil)
            } catch {
                completion(nil, error.localizedDescription)
            }
        }
    }
    
    func saveUser(_ user: User, completion: @escaping (Bool, String?) -> Void) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(user)
            let jsonObject = try JSONSerialization.jsonObject(with: data)

            guard let jsonDict = jsonObject as? [String: Any] else {
                completion(false, "Failed to serialize user data")
                return
            }

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
    
    // MARK: - Event Operations
    
    func createEvent(_ event: Event, completion: @escaping (Bool, String?) -> Void) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(event)
            let jsonObject = try JSONSerialization.jsonObject(with: data)

            guard let jsonDict = jsonObject as? [String: Any] else {
                completion(false, "Failed to serialize event data")
                return
            }

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
        db.collection("events").document(eventId).getDocument { snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(nil, "No event data found")
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let event = try JSONDecoder().decode(Event.self, from: jsonData)
                completion(event, nil)
            } catch {
                completion(nil, error.localizedDescription)
            }
        }
    }
    
    func getAllEvents(completion: @escaping ([Event]?, String?) -> Void) {
        db.collection("events").getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            var events: [Event] = []
            for document in snapshot?.documents ?? [] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: document.data())
                    let event = try JSONDecoder().decode(Event.self, from: jsonData)
                    events.append(event)
                } catch {
                    print("Error decoding event: \(error)")
                }
            }
            
            completion(events, nil)
        }
    }
    
    func getPanitiaEvents(panitiaId: String, completion: @escaping ([Event]?, String?) -> Void) {
        db.collection("events").whereField("created_by", isEqualTo: panitiaId).getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            var events: [Event] = []
            for document in snapshot?.documents ?? [] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: document.data())
                    let event = try JSONDecoder().decode(Event.self, from: jsonData)
                    events.append(event)
                } catch {
                    print("Error decoding event: \(error)")
                }
            }
            
            completion(events, nil)
        }
    }
    
    // MARK: - Ticket Operations
    
    func registerEventForPeserta(pesertaId: String, eventId: String, completion: @escaping (Bool, String?) -> Void) {
        let ticketId = UUID().uuidString
        let ticket = Ticket(
            id: ticketId,
            eventId: eventId,
            pesertaId: pesertaId,
            status: .active,
            encryptedData: generateEncryptedQRCode(ticketId: ticketId, eventId: eventId, pesertaId: pesertaId),
            createdAt: Date()
        )
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(ticket)
            let jsonObject = try JSONSerialization.jsonObject(with: data)

            guard let jsonDict = jsonObject as? [String: Any] else {
                completion(false, "Failed to serialize ticket data")
                return
            }

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
        db.collection("tickets").whereField("peserta_id", isEqualTo: pesertaId).getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            var tickets: [Ticket] = []
            for document in snapshot?.documents ?? [] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: document.data())
                    let ticket = try JSONDecoder().decode(Ticket.self, from: jsonData)
                    tickets.append(ticket)
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
            let encoder = JSONEncoder()
            let data = try encoder.encode(feedback)
            let jsonObject = try JSONSerialization.jsonObject(with: data)

            guard let jsonDict = jsonObject as? [String: Any] else {
                completion(false, "Failed to serialize feedback data")
                return
            }

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
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error.localizedDescription)
                    return
                }
                
                var feedback: [Feedback] = []
                for document in snapshot?.documents ?? [] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: document.data())
                        let fb = try JSONDecoder().decode(Feedback.self, from: jsonData)
                        feedback.append(fb)
                    } catch {
                        print("Error decoding feedback: \(error)")
                    }
                }
                
                completion(feedback, nil)
            }
    }
    
    // MARK: - Vendor Operations
    
    func addVendor(_ vendor: Vendor, completion: @escaping (Bool, String?) -> Void) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(vendor)
            let jsonObject = try JSONSerialization.jsonObject(with: data)

            guard let jsonDict = jsonObject as? [String: Any] else {
                completion(false, "Failed to serialize vendor data")
                return
            }

            db.collection("vendors").document(vendor.id).setData(jsonDict) { error in
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
    
    func getAllVendors(completion: @escaping ([Vendor]?, String?) -> Void) {
        db.collection("vendors").getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            var vendors: [Vendor] = []
            for document in snapshot?.documents ?? [] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: document.data())
                    let vendor = try JSONDecoder().decode(Vendor.self, from: jsonData)
                    vendors.append(vendor)
                } catch {
                    print("Error decoding vendor: \(error)")
                }
            }
            
            completion(vendors, nil)
        }
    }
    
    // MARK: - Catalog Operations
    
    func addCatalogItem(_ catalog: VendorCatalog, completion: @escaping (Bool, String?) -> Void) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(catalog)
            let jsonObject = try JSONSerialization.jsonObject(with: data)

            guard let jsonDict = jsonObject as? [String: Any] else {
                completion(false, "Failed to serialize catalog data")
                return
            }

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
        db.collection("catalog").whereField("vendor_id", isEqualTo: vendorId).getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            var items: [VendorCatalog] = []
            for document in snapshot?.documents ?? [] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: document.data())
                    let item = try JSONDecoder().decode(VendorCatalog.self, from: jsonData)
                    items.append(item)
                } catch {
                    print("Error decoding catalog item: \(error)")
                }
            }
            
            completion(items, nil)
        }
    }
    
    // MARK: - Invoice Operations
    
    func getVendorInvoices(vendorId: String, completion: @escaping ([Invoice]?, String?) -> Void) {
        db.collection("invoices").whereField("vendor_id", isEqualTo: vendorId).getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            var invoices: [Invoice] = []
            for document in snapshot?.documents ?? [] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: document.data())
                    let invoice = try JSONDecoder().decode(Invoice.self, from: jsonData)
                    invoices.append(invoice)
                } catch {
                    print("Error decoding invoice: \(error)")
                }
            }
            
            completion(invoices, nil)
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
                    "used_at": Date()
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
            .getDocuments { snapshot, _ in
                let feedbacks = snapshot?.documents.compactMap { doc -> Feedback? in
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: doc.data())
                        return try JSONDecoder().decode(Feedback.self, from: jsonData)
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
