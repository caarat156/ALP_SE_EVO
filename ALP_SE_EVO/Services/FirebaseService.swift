import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFunctions

class FirebaseService {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    
    // MARK: - Firestore Serialization Helpers
    
    /// Converts Firestore-native types (Timestamp, GeoPoint, etc.) that JSONSerialization
    /// cannot handle into JSON-safe equivalents. Timestamps become Double (Unix seconds).
    private func sanitizeFirestoreData(_ data: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in data {
            result[key] = sanitizeValue(value)
        }
        return result
    }
    
    private func sanitizeValue(_ value: Any) -> Any {
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue().timeIntervalSince1970
        } else if let dict = value as? [String: Any] {
            return sanitizeFirestoreData(dict)
        } else if let array = value as? [Any] {
            return array.map { sanitizeValue($0) }
        }
        return value
    }
    
    private func firestoreDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
    
    private func firestoreEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }
    
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
                let jsonData = try JSONSerialization.data(withJSONObject: self.sanitizeFirestoreData(data))
                let user = try self.firestoreDecoder().decode(User.self, from: jsonData)
                completion(user, nil)
            } catch {
                completion(nil, error.localizedDescription)
            }
        }
    }
    
    func saveUser(_ user: User, completion: @escaping (Bool, String?) -> Void) {
        do {
            let data = try firestoreEncoder().encode(user)
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
    
    func getAllUsers(completion: @escaping ([User]?, String?) -> Void) {
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            var users: [User] = []
            for document in snapshot?.documents ?? [] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: self.sanitizeFirestoreData(document.data()))
                    let user = try self.firestoreDecoder().decode(User.self, from: jsonData)
                    users.append(user)
                } catch {
                    print("Error decoding user: \(error)")
                }
            }
            
            completion(users, nil)
        }
    }
    
    // MARK: - Event Operations
    
    func createEvent(_ event: Event, completion: @escaping (Bool, String?) -> Void) {
        do {
            let data = try firestoreEncoder().encode(event)
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
    
    func deleteEvent(eventId: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("events").document(eventId).delete { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
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
                let jsonData = try JSONSerialization.data(withJSONObject: self.sanitizeFirestoreData(data))
                let event = try self.firestoreDecoder().decode(Event.self, from: jsonData)
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
                    let jsonData = try JSONSerialization.data(withJSONObject: self.sanitizeFirestoreData(document.data()))
                    let event = try self.firestoreDecoder().decode(Event.self, from: jsonData)
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
                    let jsonData = try JSONSerialization.data(withJSONObject: self.sanitizeFirestoreData(document.data()))
                    let event = try self.firestoreDecoder().decode(Event.self, from: jsonData)
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
        let data: [String: Any] = [
            "pesertaId": pesertaId,
            "eventId": eventId
        ]
        
        functions.httpsCallable("registerEvent").call(data) { [weak self] result, error in
            if let error = error {
                print("Cloud Function registerEvent failed, falling back to local transaction: \(error.localizedDescription)")
                
                guard let self = self else { return }
                let ticketId = UUID().uuidString
                let ticketRef = self.db.collection("tickets").document(ticketId)
                let eventRef = self.db.collection("events").document(eventId)
                
                self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                    let eventDoc: DocumentSnapshot
                    do {
                        eventDoc = try transaction.getDocument(eventRef)
                    } catch let fetchError as NSError {
                        errorPointer?.pointee = fetchError
                        return nil
                    }
                    
                    guard let quota = eventDoc.data()?["quota"] as? Int,
                          let registeredCount = eventDoc.data()?["registered_count"] as? Int else {
                        let err = NSError(domain: "AppError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Event data invalid"])
                        errorPointer?.pointee = err
                        return nil
                    }
                    
                    if registeredCount >= quota {
                        let err = NSError(domain: "AppError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Quota fully booked"])
                        errorPointer?.pointee = err
                        return nil
                    }
                    
                    transaction.updateData(["registered_count": registeredCount + 1], forDocument: eventRef)
                    
                    let ticket = Ticket(
                        id: ticketId,
                        eventId: eventId,
                        pesertaId: pesertaId,
                        status: .active,
                        encryptedData: self.generateEncryptedQRCode(ticketId: ticketId, eventId: eventId, pesertaId: pesertaId),
                        createdAt: Date()
                    )
                    
                    do {
                        let encoder = JSONEncoder()
                        let ticketData = try encoder.encode(ticket)
                        let jsonDict = try JSONSerialization.jsonObject(with: ticketData) as! [String: Any]
                        transaction.setData(jsonDict, forDocument: ticketRef)
                    } catch let encodeError as NSError {
                        errorPointer?.pointee = encodeError
                        return nil
                    }
                    
                    return nil
                }) { (object, err) in
                    if let err = err {
                        completion(false, err.localizedDescription)
                    } else {
                        completion(true, nil)
                    }
                }
                return
            }
            completion(true, nil)
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
        let data: [String: Any] = [
            "id": feedback.id,
            "eventId": feedback.eventId,
            "pesertaId": feedback.pesertaId,
            "rating": feedback.rating,
            "comment": feedback.comment,
            "type": feedback.type
        ]
        
        functions.httpsCallable("submitFeedback").call(data) { [weak self] result, error in
            if let error = error {
                print("Cloud Function submitFeedback failed, falling back to local write: \(error.localizedDescription)")
                
                guard let self = self else { return }
                do {
                    let encoder = JSONEncoder()
                    let feedbackData = try encoder.encode(feedback)
                    let jsonDict = try JSONSerialization.jsonObject(with: feedbackData) as! [String: Any]
                    
                    self.db.collection("feedback").document(feedback.id).setData(jsonDict) { err in
                        if let err = err {
                            completion(false, err.localizedDescription)
                        } else {
                            completion(true, nil)
                        }
                    }
                } catch {
                    completion(false, error.localizedDescription)
                }
                return
            }
            completion(true, nil)
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
        let data: [String: Any] = [
            "name": vendor.name,
            "email": vendor.email,
            "phone": vendor.phone ?? ""
        ]
        
        functions.httpsCallable("createVendorUser").call(data) { [weak self] result, error in
            if let error = error {
                print("Cloud function failed, using client fallback batch write: \(error.localizedDescription)")
                // LOCAL FALLBACK: Add directly to 'vendors' and 'users' collections
                // For demo testing in Xcode simulator
                guard let self = self else { return }
                let batch = self.db.batch()
                let userRef = self.db.collection("users").document(vendor.id)
                let vendorRef = self.db.collection("vendors").document(vendor.id)
                
                let userObj = User(id: vendor.id, email: vendor.email, name: vendor.name, role: .vendor, createdAt: Date())
                
                do {
                    let userEncoder = JSONEncoder()
                    let userData = try userEncoder.encode(userObj)
                    let userDict = try JSONSerialization.jsonObject(with: userData) as! [String: Any]
                    let vendorEncoder = JSONEncoder()
                    let vendorData = try vendorEncoder.encode(vendor)
                    let vendorDict = try JSONSerialization.jsonObject(with: vendorData) as! [String: Any]
                    
                    batch.setData(userDict, forDocument: userRef)
                    batch.setData(vendorDict, forDocument: vendorRef)
                    
                    batch.commit { error in
                        if let error = error {
                            completion(false, error.localizedDescription)
                        } else {
                            completion(true, nil)
                        }
                    }
                } catch {
                    completion(false, error.localizedDescription)
                }
            } else {
                completion(true, nil)
            }
        }
    }
    
    func getAllVendors(completion: @escaping ([Vendor]?, String?) -> Void) {
        db.collection("users").whereField("role", isEqualTo: "vendor").getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            var vendors: [Vendor] = []
            for document in snapshot?.documents ?? [] {
                let data = document.data()
                if let id = data["id"] as? String,
                   let name = data["name"] as? String,
                   let email = data["email"] as? String {
                    let phone = data["phone"] as? String ?? data["biodata"] as? String
                    
                    let vendor = Vendor(
                        id: id,
                        name: name,
                        email: email,
                        phone: phone,
                        createdAt: Date()
                    )
                    vendors.append(vendor)
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
    
    func createInvoice(_ invoice: Invoice, completion: @escaping (Bool, String?) -> Void) {
        do {
            let data = try firestoreEncoder().encode(invoice)
            let jsonObject = try JSONSerialization.jsonObject(with: data)

            guard let jsonDict = jsonObject as? [String: Any] else {
                completion(false, "Failed to serialize invoice data")
                return
            }

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
    
    func getVendorInvoices(vendorId: String, completion: @escaping ([Invoice]?, String?) -> Void) {
        db.collection("invoices").whereField("vendor_id", isEqualTo: vendorId).getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            var invoices: [Invoice] = []
            for document in snapshot?.documents ?? [] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: self.sanitizeFirestoreData(document.data()))
                    let invoice = try self.firestoreDecoder().decode(Invoice.self, from: jsonData)
                    invoices.append(invoice)
                } catch {
                    print("Error decoding invoice: \(error)")
                }
            }
            
            completion(invoices, nil)
        }
    }

    func getEventInvoices(eventId: String, completion: @escaping ([Invoice]?, String?) -> Void) {
        db.collection("invoices").whereField("event_id", isEqualTo: eventId).getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            var invoices: [Invoice] = []
            for document in snapshot?.documents ?? [] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: self.sanitizeFirestoreData(document.data()))
                    let invoice = try self.firestoreDecoder().decode(Invoice.self, from: jsonData)
                    invoices.append(invoice)
                } catch {
                    print("Error decoding invoice: \(error)")
                }
            }
            
            completion(invoices, nil)
        }
    }
    
    func updateInvoiceStatus(invoiceId: String, status: InvoiceStatus, completion: @escaping (Bool, String?) -> Void) {
        var updateDict: [String: Any] = ["status": status.rawValue]
        if status == .paid {
            updateDict["paid_at"] = Date()
        }
        
        db.collection("invoices").document(invoiceId).updateData(updateDict) { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }

    
    // MARK: - Attendance Operations
    
    func recordAttendance(eventId: String, scannedCode: String, completion: @escaping (Bool, String?) -> Void) {
        let data: [String: Any] = [
            "eventId": eventId,
            "scannedCode": scannedCode
        ]
        
        functions.httpsCallable("recordAttendance").call(data) { [weak self] result, error in
            if let error = error {
                print("Cloud Function recordAttendance failed, falling back to local write: \(error.localizedDescription)")
                
                guard let self = self else { return }
                
                // Decode from Base64 if needed
                var decodedCode = scannedCode
                if let data = Data(base64Encoded: scannedCode), let decodedString = String(data: data, encoding: .utf8), decodedString.contains("|") {
                    decodedCode = decodedString
                }
                
                let parts = decodedCode.split(separator: "|")
                let ticketId: String
                if parts.count >= 1 {
                    ticketId = String(parts[0])
                } else {
                    ticketId = decodedCode
                }
                
                self.db.collection("tickets").document(ticketId).updateData([
                    "status": "used",
                    "used_at": Date()
                ]) { err in
                    if let err = err {
                        completion(false, err.localizedDescription)
                    } else {
                        completion(true, nil)
                    }
                }
                return
            }
            completion(true, nil)
        }
    }
    
    func listenToLiveAttendance(eventId: String, completion: @escaping (Int) -> Void) -> ListenerRegistration {
        return db.collection("tickets")
            .whereField("event_id", isEqualTo: eventId)
            .whereField("status", isEqualTo: "used")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to live attendance: \(error.localizedDescription)")
                    return
                }
                let count = snapshot?.documents.count ?? 0
                completion(count)
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
