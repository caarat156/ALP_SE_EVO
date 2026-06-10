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
                if success && role == .vendor {
                    let vendorObj = Vendor(
                        id: uid,
                        name: name,
                        email: email,
                        phone: nil,
                        createdAt: Date()
                    )
                    self?.firebaseService.addVendor(vendorObj) { vendorSuccess, vendorError in
                        DispatchQueue.main.async {
                            self?.isLoading = false
                            if vendorSuccess {
                                self?.currentUser = newUser
                                self?.isLoggedIn = true
                                completion(true, nil)
                            } else {
                                completion(false, vendorError ?? "Failed to save vendor details")
                            }
                        }
                    }
                } else {
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
        let group = DispatchGroup()
        
        let usersToCreate = [
            (SampleData.samplePeserta, "password"),
            (SampleData.samplePanitia, "password"),
            (SampleData.sampleVendor, "password"),
            (SampleData.sampleAdmin, "password")
        ]
        
        var successCount = 0
        var skipCount = 0
        
        for (user, password) in usersToCreate {
            group.enter()
            Auth.auth().createUser(withEmail: user.email, password: password) { [weak self] authResult, error in
                if let error = error {
                    let nsError = error as NSError
                    // 17007 is the error code for FIRAuthErrorCodeEmailAlreadyInUse
                    if nsError.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                        skipCount += 1
                        // Still save to Firestore just in case
                        self?.firebaseService.saveUser(user) { _, _ in
                            group.leave()
                        }
                    } else {
                        print("Error creating user \(user.email): \(error.localizedDescription)")
                        group.leave()
                    }
                } else if let authResult = authResult {
                    // Update user ID to match Auth UID to prevent inconsistency
                    var newUser = user
                    newUser.id = authResult.user.uid
                    
                    self?.firebaseService.saveUser(newUser) { _, _ in
                        successCount += 1
                        if newUser.role == .vendor {
                            let vendorObj = Vendor(
                                id: newUser.id,
                                name: newUser.name,
                                email: newUser.email,
                                phone: "+62812345678",
                                createdAt: Date()
                            )
                            self?.firebaseService.addVendor(vendorObj) { _, _ in
                                // Seed catalog items for the new dynamic vendor UID
                                for var item in SampleData.sampleCatalogItems {
                                    item.vendorId = newUser.id
                                    group.enter()
                                    self?.firebaseService.addCatalogItem(item) { _, _ in
                                        group.leave()
                                    }
                                }
                                // Seed invoices for the new dynamic vendor UID
                                for var inv in SampleData.sampleInvoices {
                                    inv.vendorId = newUser.id
                                    group.enter()
                                    self?.firebaseService.createInvoice(inv) { _, _ in
                                        group.leave()
                                    }
                                }
                                group.leave()
                            }
                        } else {
                            group.leave()
                        }
                    }
                } else {
                    group.leave()
                }
            }
        }
        
        // Seed some sample events
        for event in SampleData.sampleEvents {
            group.enter()
            firebaseService.createEvent(event) { _, _ in
                group.leave()
            }
        }
        
        // Seed some sample vendors
        for vendor in SampleData.sampleVendors {
            group.enter()
            firebaseService.addVendor(vendor) { _, _ in
                group.leave()
            }
        }
        
        // Seed sample catalog items (default vendor123)
        for item in SampleData.sampleCatalogItems {
            group.enter()
            firebaseService.addCatalogItem(item) { _, _ in
                group.leave()
            }
        }
        
        // Seed sample invoices (default vendor123)
        for invoice in SampleData.sampleInvoices {
            group.enter()
            firebaseService.createInvoice(invoice) { _, _ in
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
            let message = "Data seeded. Created \(successCount) new users. (\(skipCount) already existed). Seeded \(SampleData.sampleEvents.count) events, \(SampleData.sampleVendors.count) vendors, catalogs, and invoices."
            completion(true, message)
        }
    }
}
