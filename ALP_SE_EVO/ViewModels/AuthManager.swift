import Foundation
import Firebase
import FirebaseAuth

class AuthManager: NSObject, ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    @Published var isLoading = false
    
    private let firebaseService = FirebaseService.shared
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    override init() {
        super.init()
        setupAuthStateListener()
        checkCurrentUser()
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.fetchUserData(uid: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.isLoggedIn = false
                }
            }
        }
    }
    
    private func checkCurrentUser() {
        if let user = Auth.auth().currentUser {
            fetchUserData(uid: user.uid)
        }
    }
    
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    completion(false, error.localizedDescription)
                } else if let uid = authResult?.user.uid {
                    self?.fetchUserData(uid: uid)
                    completion(true, nil)
                } else {
                    completion(false, "Unknown error occurred")
                }
            }
        }
    }
    
    func register(email: String, password: String, name: String, role: UserRole, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    completion(false, error.localizedDescription)
                }
                return
            }
            
            guard let uid = authResult?.user.uid else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    completion(false, "Failed to create user")
                }
                return
            }
            
            let newUser = User(
                id: uid,
                email: email,
                name: name,
                role: role,
                createdAt: Date()
            )
            
            self?.firebaseService.saveUser(newUser) { success, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if success {
                        self?.currentUser = newUser
                        self?.isLoggedIn = true
                        completion(true, nil)
                    } else {
                        completion(false, error ?? "Failed to save user data")
                    }
                }
            }
        }
    }
    
    private func fetchUserData(uid: String) {
        firebaseService.getUser(uid: uid) { [weak self] user, error in
            DispatchQueue.main.async {
                if let user = user {
                    self?.currentUser = user
                    self?.isLoggedIn = true
                } else {
                    self?.currentUser = nil
                    self?.isLoggedIn = false
                }
            }
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isLoggedIn = false
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Demo Seeding
    func seedDemoData(completion: @escaping (Bool, String) -> Void) {
        isLoading = true
        
        let usersToCreate = [
            (SampleData.samplePeserta, "password"),
            (SampleData.samplePanitia, "password"),
            (SampleData.sampleVendor, "password"),
            (SampleData.sampleAdmin, "password")
        ]
        
        var successCount = 0
        var skipCount = 0
        var panitiaUid = SampleData.samplePanitia.id
        var pesertaUid = SampleData.samplePeserta.id
        var vendorUid = SampleData.sampleVendor.id
        
        var errorMessages: [String] = []
        
        func seedUser(index: Int, onComplete: @escaping () -> Void) {
            if index >= usersToCreate.count {
                onComplete()
                return
            }
            
            let (user, password) = usersToCreate[index]
            Auth.auth().createUser(withEmail: user.email, password: password) { [weak self] authResult, error in
                if let error = error {
                    let nsError = error as NSError
                    if nsError.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                        skipCount += 1
                        Auth.auth().signIn(withEmail: user.email, password: password) { signInResult, signInError in
                            let realUid = signInResult?.user.uid ?? user.id
                            var updatedUser = user
                            updatedUser.id = realUid
                            
                            if updatedUser.role == .panitia { panitiaUid = realUid }
                            else if updatedUser.role == .peserta { pesertaUid = realUid }
                            else if updatedUser.role == .vendor { vendorUid = realUid }
                            
                            self?.firebaseService.saveUser(updatedUser) { success, err in
                                if !success, let err = err { errorMessages.append("Failed saving user \(user.email): \(err)") }
                                seedUser(index: index + 1, onComplete: onComplete)
                            }
                        }
                    } else {
                        errorMessages.append("Error creating user \(user.email): \(error.localizedDescription)")
                        seedUser(index: index + 1, onComplete: onComplete)
                    }
                } else if let authResult = authResult {
                    var newUser = user
                    newUser.id = authResult.user.uid
                    
                    if newUser.role == .panitia { panitiaUid = newUser.id }
                    else if newUser.role == .peserta { pesertaUid = newUser.id }
                    else if newUser.role == .vendor { vendorUid = newUser.id }
                    
                    self?.firebaseService.saveUser(newUser) { success, err in
                        if success { successCount += 1 }
                        else if let err = err { errorMessages.append("Failed saving new user \(newUser.email): \(err)") }
                        seedUser(index: index + 1, onComplete: onComplete)
                    }
                } else {
                    seedUser(index: index + 1, onComplete: onComplete)
                }
            }
        }
        
        seedUser(index: 0) {
            let dataGroup = DispatchGroup()
            
            // Seed events (linked to panitia)
            for var event in SampleData.sampleEvents {
                dataGroup.enter()
                event.createdBy = panitiaUid
                self.firebaseService.createEvent(event) { success, err in
                    if !success, let err = err { errorMessages.append("Event error: \(err)") }
                    dataGroup.leave()
                }
            }
            
            // Seed vendors
            for vendor in SampleData.sampleVendors {
                dataGroup.enter()
                self.firebaseService.saveUser(vendor) { success, err in
                    if !success, let err = err { errorMessages.append("Vendor error: \(err)") }
                    dataGroup.leave()
                }
            }
            
            // Seed catalog items
            for catalog in SampleData.sampleCatalogItems {
                dataGroup.enter()
                self.firebaseService.addCatalogItem(catalog) { success, err in
                    if !success, let err = err { errorMessages.append("Catalog error: \(err)") }
                    dataGroup.leave()
                }
            }
            
            // Seed tickets (linked to peserta)
            for ticket in SampleData.sampleTickets {
                dataGroup.enter()
                let ticketData = Ticket(
                    id: ticket.id,
                    eventId: ticket.eventId,
                    eventTitle: ticket.eventTitle,
                    pesertaId: pesertaUid,
                    status: ticket.status,
                    encryptedData: ticket.encryptedData,
                    createdAt: ticket.createdAt
                )
                self.firebaseService.seedTicket(ticketData) { success, err in
                    if !success, let err = err { errorMessages.append("Ticket error: \(err)") }
                    dataGroup.leave()
                }
            }
            
            // Seed event-vendor items (link sample vendors to sample events)
            for item in SampleData.sampleEventVendorItems {
                dataGroup.enter()
                self.firebaseService.saveEventVendorItem(item) { success, err in
                    if !success, let err = err { errorMessages.append("EventVendorItem error: \(err)") }
                    dataGroup.leave()
                }
            }
            
            dataGroup.notify(queue: .main) {
                self.isLoading = false
                let errorsStr = errorMessages.isEmpty ? "" : "\nErrors:\n" + Array(Set(errorMessages)).joined(separator: "\n")
                let message = "Data seeded! \(successCount) new users, \(skipCount) existing. \(SampleData.sampleEvents.count) events, \(SampleData.sampleVendors.count) vendors, \(SampleData.sampleCatalogItems.count) catalog items, \(SampleData.sampleTickets.count) tickets.\(errorsStr)"
                completion(true, message)
            }
        }
    }
    
    func resetDatabase(completion: @escaping (Bool, String) -> Void) {
        isLoading = true
        firebaseService.resetDatabase { [weak self] success, errorMsg in
            DispatchQueue.main.async {
                self?.isLoading = false
                if success {
                    completion(true, "Database reset successfully.")
                } else {
                    completion(false, errorMsg ?? "Failed to reset database.")
                }
            }
        }
    }
}
