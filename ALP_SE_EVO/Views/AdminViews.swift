import SwiftUI

// MARK: - Main Tab Container

struct AdminMainView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = AdminViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            AdminDashboardView(viewModel: viewModel)
                .tabItem { Label("Dashboard", systemImage: "chart.bar.xaxis") }
                .tag(0)

            AdminEventsView(viewModel: viewModel)
                .tabItem { Label("Events", systemImage: "calendar.badge.plus") }
                .tag(1)

            AdminVendorsView(viewModel: viewModel)
                .tabItem { Label("Vendors", systemImage: "person.3.fill") }
                .tag(2)

            AdminUsersView()
                .tabItem { Label("Users", systemImage: "person.2.circle.fill") }
                .tag(3)

            AdminProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(4)
        }
        .accentColor(.appAccent)
        .onAppear {
            viewModel.fetchAllEvents()
            viewModel.fetchAllVendors()
        }
    }
}

// MARK: - Dashboard

struct AdminDashboardView: View {
    @ObservedObject var viewModel: AdminViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        // Header banner
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Admin Control Center")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.appDeep)
                                Text("System-wide overview")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.appDeep.opacity(0.75))
                            }
                            Spacer()
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.title)
                                .foregroundColor(.appDeep)
                        }
                        .padding(20)
                        .background(Color.appPrimary)
                        .cornerRadius(18)
                        .shadow(color: Color.appAccent.opacity(0.18), radius: 8, x: 0, y: 4)

                        // Stat cards
                        HStack(spacing: 12) {
                            DashStatCard(
                                icon: "calendar.badge.plus",
                                title: "Total Events",
                                value: "\(viewModel.allEvents.count)"
                            )
                            DashStatCard(
                                icon: "person.3.fill",
                                title: "Vendors",
                                value: "\(viewModel.allVendors.count)"
                            )
                            DashStatCard(
                                icon: "flame.fill",
                                title: "Active",
                                value: "\(viewModel.allEvents.filter { $0.status == .ongoing }.count)"
                            )
                        }

                        // Recent Events
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Events")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.appTextPrimary)

                            if viewModel.allEvents.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 36))
                                        .foregroundColor(.appAccent.opacity(0.5))
                                    Text("No events in the system")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(.appTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(Color.appCard)
                                .cornerRadius(14)
                            } else {
                                ForEach(viewModel.allEvents.sorted(by: { $0.createdAt > $1.createdAt }).prefix(5)) { event in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(Color.appPrimary)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Image(systemName: "calendar")
                                                    .foregroundColor(.appDeep)
                                            )
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(event.title)
                                                .font(.system(.body, design: .rounded))
                                                .fontWeight(.semibold)
                                                .foregroundColor(.appTextPrimary)
                                            Text(event.eventDate.formatted(date: .abbreviated, time: .omitted))
                                                .font(.caption)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                        Spacer()
                                        Text(event.status.rawValue.capitalized)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.appPrimary.opacity(0.4))
                                            .foregroundColor(.appDeep)
                                            .cornerRadius(6)
                                    }
                                    .padding()
                                    .background(Color.appCard)
                                    .cornerRadius(14)
                                    .shadow(color: Color.appAccent.opacity(0.05), radius: 3, x: 0, y: 2)
                                }
                            }
                        }

                        // Top Vendors
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Vendors")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.appTextPrimary)

                            if viewModel.allVendors.isEmpty {
                                Text("No vendors registered")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.appTextSecondary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.appCard)
                                    .cornerRadius(14)
                            } else {
                                ForEach(viewModel.allVendors.prefix(5)) { vendor in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(Color.appPrimary)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Image(systemName: "building.2.fill")
                                                    .foregroundColor(.appDeep)
                                            )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(vendor.name)
                                                .font(.system(.body, design: .rounded))
                                                .fontWeight(.semibold)
                                                .foregroundColor(.appTextPrimary)
                                            Text(vendor.email)
                                                .font(.caption)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.appCard)
                                    .cornerRadius(14)
                                    .shadow(color: Color.appAccent.opacity(0.05), radius: 3, x: 0, y: 2)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Admin Dashboard")
        }
    }
}

// MARK: - Events Management

struct AdminEventsView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var showCreateEvent = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView().tint(.appAccent)
                            Text("Loading events...").font(.caption).foregroundColor(.appTextSecondary)
                        }
                        Spacer()
                    } else if viewModel.allEvents.isEmpty {
                        Spacer()
                        VStack(spacing: 14) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 54))
                                .foregroundColor(.appAccent.opacity(0.5))
                            Text("No events in the system")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.allEvents) { event in
                                    NavigationLink(destination: AdminEventDetailView(event: event, viewModel: viewModel)) {
                                        HStack(spacing: 14) {
                                            Circle()
                                                .fill(Color.appPrimary)
                                                .frame(width: 46, height: 46)
                                                .overlay(
                                                    Image(systemName: "calendar.badge.clock")
                                                        .foregroundColor(.appDeep)
                                                )
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(event.title)
                                                    .font(.system(.body, design: .rounded))
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.appTextPrimary)
                                                HStack(spacing: 10) {
                                                    Text(event.status.rawValue.capitalized)
                                                        .font(.caption)
                                                        .foregroundColor(eventStatusColor(event.status))
                                                    Text("\(event.registeredCount)/\(event.quota)")
                                                        .font(.caption)
                                                        .foregroundColor(.appTextSecondary)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                        .padding()
                                        .background(Color.appCard)
                                        .cornerRadius(14)
                                        .shadow(color: Color.appAccent.opacity(0.06), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                            .padding()
                        }
                    }

                    Button(action: { showCreateEvent = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill").foregroundColor(.appDeep)
                            Text("Create Event").fontWeight(.bold).foregroundColor(.appDeep)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appPrimary)
                        .cornerRadius(14)
                        .shadow(color: Color.appAccent.opacity(0.20), radius: 6, x: 0, y: 3)
                        .padding()
                    }
                }
            }
            .navigationTitle("Events Management")
            .sheet(isPresented: $showCreateEvent) {
                AdminCreateEventView(viewModel: viewModel)
            }
        }
    }

    private func eventStatusColor(_ status: EventStatus) -> Color {
        switch status {
        case .upcoming:  return .appAccent
        case .ongoing:   return .appOrange
        case .completed: return .appGreen
        case .cancelled: return .appRed
        }
    }
}

// MARK: - Admin Create Event

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
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        FormCard(title: "Event Information") {
                            VStack(spacing: 12) {
                                UIFormField(label: "Event Title", icon: "textformat") {
                                    TextField("Enter event title", text: $title)
                                        .foregroundColor(.appTextPrimary)
                                }
                                Divider().background(Color.appDivider)
                                UIFormField(label: "Location", icon: "mappin.and.ellipse") {
                                    TextField("Enter location", text: $location)
                                        .foregroundColor(.appTextPrimary)
                                }
                                Divider().background(Color.appDivider)
                                DatePicker("Event Date", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                                    .foregroundColor(.appTextPrimary)
                                    .tint(.appAccent)
                            }
                        }

                        FormCard(title: "Description") {
                            TextEditor(text: $description)
                                .frame(height: 110)
                                .padding(6)
                                .background(Color.appBackground)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appDivider, lineWidth: 1))
                                .foregroundColor(.appTextPrimary)
                        }

                        FormCard(title: "Capacity") {
                            Stepper(value: $quota, in: 1...10000, step: 10) {
                                HStack {
                                    Text("Event Quota").foregroundColor(.appTextPrimary)
                                    Spacer()
                                    Text("\(quota)").fontWeight(.bold).foregroundColor(.appAccent)
                                }
                            }.tint(.appAccent)
                        }

                        if !errorMessage.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill").foregroundColor(.appRed)
                                Text(errorMessage).font(.caption).foregroundColor(.appRed)
                            }
                            .padding()
                            .background(Color.appRed.opacity(0.08))
                            .cornerRadius(10)
                        }

                        Button(action: createEvent) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Create Event").fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(title.isEmpty ? Color.appAccent.opacity(0.4) : Color.appAccent)
                        .cornerRadius(14)
                        .disabled(title.isEmpty || isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle("Create Global Event")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.appAccent)
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
            if success { dismiss() }
            else { errorMessage = error ?? "Failed to create event" }
        }
    }
}

// MARK: - Admin Event Detail

struct AdminEventDetailView: View {
    let event: Event
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {

                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.title)
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.appDeep)
                        HStack(spacing: 14) {
                            Label {
                                Text(event.eventDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.appDeep.opacity(0.8))
                            } icon: {
                                Image(systemName: "calendar").foregroundColor(.appDeep)
                            }
                            Label {
                                Text(event.location)
                                    .font(.caption)
                                    .foregroundColor(.appDeep.opacity(0.8))
                            } icon: {
                                Image(systemName: "mappin.and.ellipse").foregroundColor(.appDeep)
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appPrimary)
                    .cornerRadius(16)

                    // Info rows
                    VStack(spacing: 0) {
                        AdminDetailRow(label: "Status", value: event.status.rawValue.capitalized)
                        Divider().background(Color.appDivider).padding(.leading, 16)
                        AdminDetailRow(label: "Participants", value: "\(event.registeredCount)/\(event.quota)")
                        Divider().background(Color.appDivider).padding(.leading, 16)
                        AdminDetailRow(label: "Quota", value: "\(event.quota)")
                    }
                    .background(Color.appCard)
                    .cornerRadius(14)

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.appTextSecondary)
                        Text(event.description)
                            .font(.body)
                            .foregroundColor(.appTextPrimary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appCard)
                    .cornerRadius(14)

                    // Delete button
                    Button(role: .destructive, action: deleteEvent) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Event").fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appRed)
                        .cornerRadius(14)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteEvent() {
        FirebaseService.shared.deleteEvent(eventId: event.id) { success, _ in
            if success { viewModel.fetchAllEvents(); dismiss() }
        }
    }
}

struct AdminDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.appTextSecondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.appTextPrimary)
        }
        .padding()
    }
}

// MARK: - Vendors Management

struct AdminVendorsView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var showAddVendor = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView().tint(.appAccent)
                            Text("Loading vendors...").font(.caption).foregroundColor(.appTextSecondary)
                        }
                        Spacer()
                    } else if viewModel.allVendors.isEmpty {
                        Spacer()
                        VStack(spacing: 14) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 54))
                                .foregroundColor(.appAccent.opacity(0.5))
                            Text("No vendors registered")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.allVendors) { vendor in
                                    NavigationLink(destination: AdminVendorDetailView(vendor: vendor)) {
                                        HStack(spacing: 14) {
                                            Circle()
                                                .fill(Color.appPrimary)
                                                .frame(width: 46, height: 46)
                                                .overlay(
                                                    Image(systemName: "building.2.fill")
                                                        .foregroundColor(.appDeep)
                                                )
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(vendor.name)
                                                    .font(.system(.body, design: .rounded))
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.appTextPrimary)
                                                Text(vendor.email)
                                                    .font(.caption)
                                                    .foregroundColor(.appTextSecondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                        .padding()
                                        .background(Color.appCard)
                                        .cornerRadius(14)
                                        .shadow(color: Color.appAccent.opacity(0.06), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                            .padding()
                        }
                    }

                    Button(action: { showAddVendor = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill").foregroundColor(.appDeep)
                            Text("Add Vendor").fontWeight(.bold).foregroundColor(.appDeep)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appPrimary)
                        .cornerRadius(14)
                        .shadow(color: Color.appAccent.opacity(0.20), radius: 6, x: 0, y: 3)
                        .padding()
                    }
                }
            }
            .navigationTitle("Vendors Management")
            .sheet(isPresented: $showAddVendor) {
                AdminAddVendorView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Add Vendor Sheet

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
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        FormCard(title: "Vendor Information") {
                            VStack(spacing: 12) {
                                UIFormField(label: "Vendor Name", icon: "building.2") {
                                    TextField("Enter vendor name", text: $name)
                                        .foregroundColor(.appTextPrimary)
                                }
                                Divider().background(Color.appDivider)
                                UIFormField(label: "Email", icon: "envelope") {
                                    TextField("vendor@email.com", text: $email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .foregroundColor(.appTextPrimary)
                                }
                                Divider().background(Color.appDivider)
                                UIFormField(label: "Phone", icon: "phone") {
                                    TextField("08xx-xxxx-xxxx", text: $phone)
                                        .keyboardType(.phonePad)
                                        .foregroundColor(.appTextPrimary)
                                }
                            }
                        }

                        if !errorMessage.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill").foregroundColor(.appRed)
                                Text(errorMessage).font(.caption).foregroundColor(.appRed)
                            }
                            .padding()
                            .background(Color.appRed.opacity(0.08))
                            .cornerRadius(10)
                        }

                        Button(action: addVendor) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Add Vendor").fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(name.isEmpty || email.isEmpty ? Color.appAccent.opacity(0.4) : Color.appAccent)
                        .cornerRadius(14)
                        .disabled(name.isEmpty || email.isEmpty || isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Vendor")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.appAccent)
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
            if success { dismiss() }
            else { errorMessage = error ?? "Failed to add vendor" }
        }
    }
}

// MARK: - Vendor Detail

struct AdminVendorDetailView: View {
    let vendor: Vendor

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {

                    // Avatar header
                    VStack(spacing: 10) {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.appDeep)
                            )
                        Text(vendor.name)
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.appTextPrimary)
                        Text("Vendor Partner")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.appCard)
                    .cornerRadius(16)

                    // Info rows
                    VStack(spacing: 0) {
                        ProfileInfoRow(icon: "envelope.fill", label: "Email", value: vendor.email)
                        if let phone = vendor.phone {
                            Divider().background(Color.appDivider).padding(.leading, 54)
                            ProfileInfoRow(icon: "phone.fill", label: "Phone", value: phone)
                        }
                        Divider().background(Color.appDivider).padding(.leading, 54)
                        ProfileInfoRow(
                            icon: "calendar.badge.clock",
                            label: "Member Since",
                            value: vendor.createdAt.formatted(date: .abbreviated, time: .omitted)
                        )
                    }
                    .background(Color.appCard)
                    .cornerRadius(14)
                }
                .padding()
            }
        }
        .navigationTitle("Vendor Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Users Management

struct AdminUsersView: View {
    @State private var allUsers: [User] = []
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                Group {
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView().tint(.appAccent)
                            Text("Loading users...").font(.caption).foregroundColor(.appTextSecondary)
                        }
                    } else if allUsers.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "person.2.circle.fill")
                                .font(.system(size: 52))
                                .foregroundColor(.appAccent.opacity(0.5))
                            Text("No users found")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(allUsers.sorted(by: { $0.email < $1.email })) { user in
                                    HStack(spacing: 14) {
                                        Circle()
                                            .fill(roleBg(user.role))
                                            .frame(width: 46, height: 46)
                                            .overlay(
                                                Image(systemName: roleIcon(user.role))
                                                    .foregroundColor(.appDeep)
                                                    .font(.system(size: 18))
                                            )
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(user.name)
                                                .font(.system(.body, design: .rounded))
                                                .fontWeight(.semibold)
                                                .foregroundColor(.appTextPrimary)
                                            Text(user.email)
                                                .font(.caption)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                        Spacer()
                                        Text(user.role.rawValue.capitalized)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(roleBg(user.role).opacity(0.6))
                                            .foregroundColor(.appDeep)
                                            .cornerRadius(6)
                                    }
                                    .padding()
                                    .background(Color.appCard)
                                    .cornerRadius(14)
                                    .shadow(color: Color.appAccent.opacity(0.06), radius: 4, x: 0, y: 2)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Users Management")
            .onAppear { loadUsers() }
        }
    }

    private func loadUsers() {
        isLoading = true
        FirebaseService.shared.getAllUsers { list, _ in
            DispatchQueue.main.async {
                self.isLoading = false
                if let list = list { self.allUsers = list }
            }
        }
    }

    private func roleBg(_ role: UserRole) -> Color {
        switch role {
        case .peserta: return Color.appPrimary
        case .panitia: return Color.appAccent.opacity(0.35)
        case .vendor:  return Color.appGreen.opacity(0.25)
        case .admin:   return Color.appRed.opacity(0.20)
        }
    }

    private func roleIcon(_ role: UserRole) -> String {
        switch role {
        case .peserta: return "person.fill"
        case .panitia: return "person.badge.shield.checkmark.fill"
        case .vendor:  return "building.2.fill"
        case .admin:   return "shield.lefthalf.filled"
        }
    }
}

// MARK: - Admin Profile

struct AdminProfileView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        // Avatar header
                        VStack(spacing: 10) {
                            Circle()
                                .fill(Color.appPrimary)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "shield.lefthalf.filled")
                                        .font(.system(size: 32))
                                        .foregroundColor(.appDeep)
                                )
                            Text(authManager.currentUser?.name ?? "Admin")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.appTextPrimary)
                            Text("Administrator")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.appRed.opacity(0.15))
                                .foregroundColor(.appRed)
                                .cornerRadius(6)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.appCard)
                        .cornerRadius(16)

                        // Info rows
                        VStack(spacing: 0) {
                            ProfileInfoRow(icon: "person.fill", label: "Name", value: authManager.currentUser?.name ?? "N/A")
                            Divider().background(Color.appDivider).padding(.leading, 54)
                            ProfileInfoRow(icon: "envelope.fill", label: "Email", value: authManager.currentUser?.email ?? "N/A")
                            Divider().background(Color.appDivider).padding(.leading, 54)
                            ProfileInfoRow(icon: "shield.lefthalf.filled", label: "Role", value: "Administrator")
                        }
                        .background(Color.appCard)
                        .cornerRadius(16)

                        Button(action: { authManager.logout() }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Logout").fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appRed)
                            .cornerRadius(14)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Admin Profile")
        }
    }
}

#Preview {
    AdminMainView()
        .environmentObject(AuthManager())
}
