# Project Structure & File Organization

## Directory Overview

```
ALP_SE_EVO/
│
├── ALP_SE_EVO/
│   ├── ALP_SE_EVOApp.swift          # Main app entry point
│   ├── ContentView.swift             # Login view
│   │
│   ├── Models/
│   │   ├── User.swift               # User model with role enum
│   │   ├── Event.swift              # Event model and status enum
│   │   ├── Ticket.swift             # Ticket model with encryption
│   │   ├── Vendor.swift             # Vendor, Catalog, Invoice models
│   │   └── Feedback.swift           # Feedback, Review, Form models
│   │
│   ├── ViewModels/
│   │   ├── AuthManager.swift        # Authentication & session management
│   │   ├── ViewModels.swift         # PesertaVM, PanitiaVM, VendorVM, AdminVM
│   │   └── NavigationManager.swift  # Navigation state management
│   │
│   ├── Services/
│   │   └── FirebaseService.swift    # Firestore database operations
│   │
│   ├── Views/
│   │   ├── PesertaViews.swift       # All views untuk peserta
│   │   ├── PanitiaViews.swift       # All views untuk panitia
│   │   ├── VendorViews.swift        # All views untuk vendor
│   │   └── AdminViews.swift         # All views untuk admin
│   │
│   ├── Utilities/
│   │   ├── Extensions.swift         # String, Date, Color, View extensions
│   │   └── SampleData.swift         # Mock data for testing
│   │
│   ├── Assets.xcassets/             # Images & colors
│   └── GoogleService-Info.plist     # Firebase config (download dari console)
│
├── ALP_SE_EVOTests/
│   └── ALP_SE_EVOTests.swift        # Unit tests
│
├── ALP_SE_EVOUITests/
│   ├── ALP_SE_EVOUITests.swift
│   └── ALP_SE_EVOUITestsLaunchTests.swift
│
├── ALP_SE_EVO.xcodeproj/
│
├── README.md                         # Project documentation
├── FIREBASE_SETUP.md                # Firebase setup guide
└── PROJECT_STRUCTURE.md             # This file
```

## Key Components Breakdown

### 1. Models (5 files)

**User.swift**
- `enum UserRole`: peserta, panitia, vendor, admin
- `struct User`: Identifiable user with email, name, role, biodata

**Event.swift**
- `enum EventStatus`: upcoming, ongoing, completed, cancelled
- `struct Event`: Event details dengan quota dan attendance tracking
- `struct EventRecap`: Summary data dari event (attendance, feedback, ratings)

**Ticket.swift**
- `enum TicketStatus`: active, used, cancelled
- `struct Ticket`: QR ticket dengan encrypted data
- `struct QRCodeData`: Data untuk QR code generation

**Vendor.swift**
- `struct Vendor`: Vendor profile
- `struct VendorCatalog`: Product catalog items
- `enum InvoiceStatus`: unpaid, paid, overdue, cancelled
- `struct Invoice`: Invoice dengan tracking dan payment status

**Feedback.swift**
- `struct Feedback`: Event feedback dari peserta
- `struct VendorReview`: Review vendor dari panitia
- `struct FormField & EventForm`: Dynamic form building
- `struct FormResponse`: User responses to forms

### 2. ViewModels (2 files)

**AuthManager.swift** (Main State Manager)
- `@Published var currentUser: User?` - Current logged in user
- `@Published var isLoggedIn: Bool` - Login state
- `func login()` - Firebase auth login
- `func register()` - Create new user
- `func logout()` - Sign out

**ViewModels.swift** (Role-specific ViewModels)
- `PesertaViewModel` - Events, tickets, feedback management
- `PanitiaViewModel` - Event management, attendance, recap
- `VendorViewModel` - Catalog, invoices
- `AdminViewModel` - Global management, users, vendors

**NavigationManager.swift**
- `@Published var currentTab: Int` - Tab navigation
- `@Published var selectedEvent: Event?` - Event selection
- `@Published var showingQRScanner: Bool` - Modal state

### 3. Services (1 file)

**FirebaseService.swift** - Singleton service dengan methods:
```
// User Operations
- getUser(uid, completion)
- saveUser(_, completion)

// Event Operations
- createEvent(_, completion)
- getEvent(_, completion)
- getAllEvents(completion)
- getPanitiaEvents(panitiaId, completion)

// Ticket Operations
- registerEventForPeserta(pesertaId, eventId, completion)
- getTickets(pesertaId, completion)
- getRegisteredEvents(pesertaId, completion)

// Feedback Operations
- saveFeedback(_, completion)
- getFeedback(eventId, targetId, completion)

// Vendor Operations
- addVendor(_, completion)
- getAllVendors(completion)

// Catalog Operations
- addCatalogItem(_, completion)
- getVendorCatalog(vendorId, completion)

// Invoice Operations
- getVendorInvoices(vendorId, completion)

// Attendance Operations
- recordAttendance(eventId, pesertaId, completion)

// Event Recap
- getEventRecap(eventId, completion)
```

### 4. Views (5 files)

**ContentView.swift** (Login)
- Login form dengan email dan password
- Demo credentials display
- Error messaging

**PesertaViews.swift** (5 main views)
1. `PesertaMainView` - TabView container
2. `PesertaHomeView` - Dashboard dengan welcome & recent activity
3. `PesertaEventsView` - Registered events list
4. `PesertaTicketsView` - Ticket management
5. `PesertaProfileView` - User profile & settings

**PanitiaViews.swift** (6 main views)
1. `PanitiaMainView` - TabView container
2. `PanitiaDashboardView` - Event overview & statistics
3. `PanitiaEventsView` - Event management
4. `EventManagementView` - Event details & actions
5. `QRScannerView` - QR scanning untuk check-in
6. `EventRecapView` - Event report & analytics

**VendorViews.swift** (4 main views)
1. `VendorMainView` - TabView container
2. `VendorCatalogView` - Catalog management
3. `VendorInvoicesView` - Invoice tracking
4. `VendorProfileView` - Profile settings

**AdminViews.swift** (5 main views)
1. `AdminMainView` - TabView container
2. `AdminDashboardView` - System overview
3. `AdminEventsView` - Event management
4. `AdminVendorsView` - Vendor management
5. `AdminUsersView` - User management

### 5. Utilities (2 files)

**Extensions.swift**
- String: `isValidEmail()`, `isValidPassword()`
- Date: `isToday()`, `isTomorrow()`, `timeUntilNow()`
- Double: `formatted()`
- Color: Custom colors
- View: Corner radius customization
- Validation helpers & formatters

**SampleData.swift**
- Sample users untuk testing
- Sample events, tickets, vendors
- `MockFirebaseService` untuk testing tanpa Firebase

## Architecture Pattern: MVVM

```
View (SwiftUI)
    ↓
ViewModel (@ObservedObject, @StateObject)
    ↓
Model (Codable structs)
    ↓
Service (FirebaseService.shared)
    ↓
Firebase (Firestore Database)
```

## Data Flow Example: Registering for Event

```
1. User Input
   └─→ PesertaEventsView (View)

2. Action Handler
   └─→ registerEvent() method (View)

3. ViewModel Layer
   └─→ PesertaViewModel.registerEvent() (@ObservedObject)

4. Service Layer
   └─→ FirebaseService.registerEventForPeserta() (Singleton)

5. Database Layer
   └─→ Firestore Collection "tickets"

6. Response Back
   └─→ Completion handler updates @Published properties

7. UI Update
   └─→ SwiftUI automatically re-renders (@Published observers)
```

## Environment Objects Flow

```
ALP_SE_EVOApp
├─ @StateObject authManager: AuthManager
│  └─ Provides: @Published currentUser, isLoggedIn
│
└─ All child views:
   ├─ @EnvironmentObject authManager
   ├─ @EnvironmentObject navigationManager
   └─ @StateObject roleSpecificViewModels
```

## Testing Guides

### Unit Testing
```swift
// Test models
func testUserModel() {
    let user = User(...)
    XCTAssertEqual(user.role, .peserta)
}

// Test ViewModels
func testAuthManager() {
    let auth = AuthManager()
    auth.login(email: "test@test.com", password: "pass123") { success, error in
        XCTAssertTrue(success)
    }
}
```

### UI Testing
- Use mock Firebase service
- Test navigation flows
- Test form validation

## Key Design Decisions

1. **MVVM** - Better testability dan state management
2. **Singleton FirebaseService** - Consistent DB access
3. **Environment Objects** - Global state without drilling
4. **Codable Models** - Easy JSON serialization
5. **SwiftUI** - Modern, declarative UI
6. **Tab Navigation** - Easy access ke main features

## Adding New Feature Checklist

- [ ] Create Model in Models/
- [ ] Add ViewModel methods
- [ ] Implement FirebaseService methods
- [ ] Create View files
- [ ] Update ALP_SE_EVOApp navigation if needed
- [ ] Add unit tests
- [ ] Test with sample data
- [ ] Update README with new feature

## Common Code Patterns

### ViewModel with @Published
```swift
class MyViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    
    private let firebaseService = FirebaseService.shared
    
    func fetchItems() {
        isLoading = true
        firebaseService.getItems { [weak self] items, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.items = items ?? []
            }
        }
    }
}
```

### View with EnvironmentObject
```swift
struct MyView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = MyViewModel()
    
    var body: some View {
        VStack {
            Text(authManager.currentUser?.name ?? "")
            List(viewModel.items) { item in
                Text(item.name)
            }
        }
        .onAppear {
            viewModel.fetchItems()
        }
    }
}
```

### Firebase Operation Pattern
```swift
func operation(completion: @escaping (Bool, String?) -> Void) {
    db.collection("path").operation { snapshot, error in
        if let error = error {
            completion(false, error.localizedDescription)
            return
        }
        
        // Process data
        completion(true, nil)
    }
}
```

---

**Last Updated:** June 2, 2026
**Version:** 1.0
