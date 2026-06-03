import SwiftUI

struct AdminMainView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = AdminViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            AdminDashboardView(viewModel: viewModel)
                .tabItem {
                    Text("Dashboard")
                }
                .tag(0)
            
            // Events Tab
            AdminEventsView(viewModel: viewModel)
                .tabItem {
                    Text("Events")
                }
                .tag(1)
            
            // Vendors Tab
            AdminVendorsView(viewModel: viewModel)
                .tabItem {
                    Text("Vendors")
                }
                .tag(2)
            
            // Users Tab
            AdminUsersView()
                .tabItem {
                    Text("Users")
                }
                .tag(3)
            
            // Profile Tab
            AdminProfileView()
                .tabItem {
                    Text("Profile")
                }
                .tag(4)
        }
        .onAppear {
            viewModel.fetchAllEvents()
            viewModel.fetchAllVendors()
        }
    }
}

struct AdminDashboardView: View {
    @ObservedObject var viewModel: AdminViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("System Overview")) {
                        HStack {
                            Text("Total Events")
                            Spacer()
                            Text("\(viewModel.allEvents.count)")
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text("Total Vendors")
                            Spacer()
                            Text("\(viewModel.allVendors.count)")
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text("Active Events")
                            Spacer()
                            Text("\(viewModel.allEvents.filter { $0.status == .ongoing }.count)")
                                .fontWeight(.bold)
                        }
                    }
                    
                    Section(header: Text("Recent Events")) {
                        if viewModel.allEvents.isEmpty {
                            Text("No events")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(viewModel.allEvents.sorted(by: { $0.createdAt > $1.createdAt }).prefix(5)) { event in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(.headline)
                                    Text(event.eventDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Top Vendors")) {
                        if viewModel.allVendors.isEmpty {
                            Text("No vendors")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(viewModel.allVendors.prefix(5)) { vendor in
                                Text(vendor.name)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Admin Dashboard")
        }
    }
}

struct AdminEventsView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var showCreateEvent = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.allEvents.isEmpty {
                    Text("No events")
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(viewModel.allEvents) { event in
                            NavigationLink(destination: AdminEventDetailView(event: event)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(.headline)
                                    HStack(spacing: 12) {
                                        Text(event.status.rawValue.capitalized)
                                            .font(.caption)
                                            .foregroundColor(statusColor(event.status))
                                        Text("\(event.registeredCount)/\(event.quota)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Button(action: { showCreateEvent = true }) {
                    Text("Create Event")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                }
            }
            .navigationTitle("Events Management")
            .sheet(isPresented: $showCreateEvent) {
                AdminCreateEventView(viewModel: viewModel)
            }
        }
    }
    
    private func statusColor(_ status: EventStatus) -> Color {
        switch status {
        case .upcoming:
            return .blue
        case .ongoing:
            return .orange
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
}

struct AdminCreateEventView: View {
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var eventDate = Date()
    @State private var location = ""
    @State private var quota = 100
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Information")) {
                    TextField("Event Title", text: $title)
                    TextField("Location", text: $location)
                    DatePicker("Event Date", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Description")) {
                    TextEditor(text: $description)
                        .frame(height: 120)
                }
                
                Section(header: Text("Capacity")) {
                    Stepper(value: $quota, in: 1...10000, step: 10) {
                        HStack {
                            Text("Event Quota")
                            Spacer()
                            Text("\(quota)")
                                .fontWeight(.bold)
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: createEvent) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Create Event")
                        }
                    }
                    .disabled(title.isEmpty || isLoading)
                }
            }
            .navigationTitle("Create Global Event")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createEvent() {
        guard let userId = authManager.currentUser?.id else { return }
        isLoading = true
        
        let event = Event(
            id: UUID().uuidString,
            title: title,
            description: description,
            eventDate: eventDate,
            location: location,
            quota: quota,
            registeredCount: 0,
            status: .upcoming,
            createdBy: userId,
            createdAt: Date()
        )
        
        viewModel.createGlobalEvent(event: event) { success, error in
            isLoading = false
            if success {
                dismiss()
            } else {
                errorMessage = error ?? "Failed to create event"
            }
        }
    }
}

struct AdminEventDetailView: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.eventDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(event.location)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                HStack {
                    Text("Status")
                    Spacer()
                    Text(event.status.rawValue.capitalized)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Participants")
                    Spacer()
                    Text("\(event.registeredCount)/\(event.quota)")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Description")
                    Spacer()
                }
                Text(event.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Event Details")
    }
}

struct AdminVendorsView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var showAddVendor = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.allVendors.isEmpty {
                    Text("No vendors")
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(viewModel.allVendors) { vendor in
                            NavigationLink(destination: AdminVendorDetailView(vendor: vendor)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(vendor.name)
                                        .font(.headline)
                                    Text(vendor.email)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            // Delete vendor functionality
                        }
                    }
                }
                
                Button(action: { showAddVendor = true }) {
                    Text("Add Vendor")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                }
            }
            .navigationTitle("Vendors Management")
            .sheet(isPresented: $showAddVendor) {
                AdminAddVendorView(viewModel: viewModel)
            }
        }
    }
}

struct AdminAddVendorView: View {
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vendor Information")) {
                    TextField("Vendor Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: addVendor) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Add Vendor")
                        }
                    }
                    .disabled(name.isEmpty || email.isEmpty || isLoading)
                }
            }
            .navigationTitle("Add Vendor")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addVendor() {
        isLoading = true
        
        let vendor = Vendor(
            id: UUID().uuidString,
            name: name,
            email: email,
            phone: phone,
            createdAt: Date()
        )
        
        viewModel.addVendor(vendor: vendor) { success, error in
            isLoading = false
            if success {
                dismiss()
            } else {
                errorMessage = error ?? "Failed to add vendor"
            }
        }
    }
}

struct AdminVendorDetailView: View {
    let vendor: Vendor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(vendor.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vendor.email)
                            .font(.caption)
                            .foregroundColor(.gray)
                        if let phone = vendor.phone {
                            Text(phone)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                HStack {
                    Text("Member Since")
                    Spacer()
                    Text(vendor.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Vendor Details")
    }
}

struct AdminUsersView: View {
    @State private var allUsers: [User] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                } else if allUsers.isEmpty {
                    Text("No users")
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(allUsers.sorted(by: { $0.email < $1.email })) { user in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(user.name)
                                        .font(.headline)
                                    Spacer()
                                    Text(user.role.rawValue.capitalized)
                                        .font(.caption)
                                        .padding(4)
                                        .background(roleColor(user.role).opacity(0.2))
                                        .foregroundColor(roleColor(user.role))
                                        .cornerRadius(4)
                                }
                                
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Users Management")
            .onAppear {
                loadUsers()
            }
        }
    }
    
    private func loadUsers() {
        // Load all users from Firebase
        isLoading = true
        // Implementation here
    }
    
    private func roleColor(_ role: UserRole) -> Color {
        switch role {
        case .peserta:
            return .blue
        case .panitia:
            return .purple
        case .vendor:
            return .green
        case .admin:
            return .red
        }
    }
}

struct AdminProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Administrator Profile")) {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(authManager.currentUser?.name ?? "N/A")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(authManager.currentUser?.email ?? "N/A")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Role")
                            Spacer()
                            Text("Administrator")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Section {
                        Button(action: logout) {
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Admin Profile")
        }
    }
    
    private func logout() {
        authManager.logout()
    }
}

#Preview {
    AdminMainView()
        .environmentObject(AuthManager())
}
