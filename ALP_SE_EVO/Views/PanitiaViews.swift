import SwiftUI
import Firebase
import FirebaseFirestore

// MARK: - Main Tab Container

struct PanitiaMainView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = PanitiaViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            PanitiaDashboardView(viewModel: viewModel)
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
                .tag(0)

            PanitiaEventsView(viewModel: viewModel)
                .tabItem { Label("Events", systemImage: "calendar") }
                .tag(1)

            AttendanceView(viewModel: viewModel)
                .tabItem { Label("Attendance", systemImage: "checkmark.seal.fill") }
                .tag(2)

            PanitiaProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(3)
        }
        .accentColor(.appAccent)
        .onAppear {
            if let userId = authManager.currentUser?.id {
                viewModel.fetchManagedEvents(panitiaId: userId)
            }
        }
    }
}

// MARK: - Dashboard

struct PanitiaDashboardView: View {
    @ObservedObject var viewModel: PanitiaViewModel
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        // Greeting header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back,")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.appDeep.opacity(0.8))
                                Text(authManager.currentUser?.name ?? "Panitia")
                                    .font(.system(.title2, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.appDeep)
                            }
                            Spacer()
                            Image(systemName: "person.badge.shield.checkmark.fill")
                                .font(.title)
                                .foregroundColor(.appDeep)
                        }
                        .padding(20)
                        .background(Color.appPrimary)
                        .cornerRadius(18)
                        .shadow(color: Color.appAccent.opacity(0.18), radius: 8, x: 0, y: 4)

                        // Stat cards row
                        HStack(spacing: 12) {
                            DashStatCard(
                                icon: "calendar.badge.plus",
                                title: "Total Events",
                                value: "\(viewModel.managedEvents.count)"
                            )
                            DashStatCard(
                                icon: "flame.fill",
                                title: "Active",
                                value: "\(viewModel.managedEvents.filter { $0.status == .ongoing }.count)"
                            )
                            DashStatCard(
                                icon: "checkmark.seal.fill",
                                title: "Done",
                                value: "\(viewModel.managedEvents.filter { $0.status == .completed }.count)"
                            )
                        }

                        // Recent Events
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Events")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.appTextPrimary)

                            if viewModel.managedEvents.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 36))
                                        .foregroundColor(.appAccent.opacity(0.5))
                                    Text("No events yet")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(.appTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(Color.appCard)
                                .cornerRadius(14)
                            } else {
                                ForEach(viewModel.managedEvents.prefix(3)) { event in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(Color.appPrimary)
                                            .frame(width: 42, height: 42)
                                            .overlay(
                                                Image(systemName: "calendar")
                                                    .foregroundColor(.appDeep)
                                            )
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(event.title)
                                                .font(.system(.body, design: .rounded))
                                                .fontWeight(.semibold)
                                                .foregroundColor(.appTextPrimary)
                                            Text("Participants: \(event.registeredCount)/\(event.quota)")
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
                                    .shadow(color: Color.appAccent.opacity(0.06), radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}

// Reusable stat card for dashboard
struct DashStatCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appDeep)
            Text(value)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.appTextPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.appPrimary)
        .cornerRadius(14)
        .shadow(color: Color.appAccent.opacity(0.14), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Events List

struct PanitiaEventsView: View {
    @ObservedObject var viewModel: PanitiaViewModel
    @State private var showCreateEvent = false
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    if viewModel.managedEvents.isEmpty {
                        Spacer()
                        VStack(spacing: 14) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 54))
                                .foregroundColor(.appAccent.opacity(0.5))
                            Text("No events created yet")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                            Text("Tap below to create your first event.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.managedEvents) { event in
                                    NavigationLink(destination: EventManagementView(event: event, viewModel: viewModel)) {
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
                                                        .foregroundColor(eventStatusFg(event.status))
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
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.appDeep)
                            Text("Create New Event")
                                .fontWeight(.bold)
                                .foregroundColor(.appDeep)
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
            .navigationTitle("Events")
            .sheet(isPresented: $showCreateEvent) {
                CreateEventView(viewModel: viewModel)
            }
        }
    }

    private func eventStatusFg(_ status: EventStatus) -> Color {
        switch status {
        case .upcoming:  return .appAccent
        case .ongoing:   return .appOrange
        case .completed: return .appGreen
        case .cancelled: return .appRed
        }
    }
}

// MARK: - Create Event Sheet

struct CreateEventView: View {
    @ObservedObject var viewModel: PanitiaViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager

    @State private var title = ""
    @State private var description = ""
    @State private var eventDate = Date()
    @State private var location = ""
    @State private var quota = 100
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var vendors: [Vendor] = []
    @State private var selectedVendorId = ""
    @State private var catalogItems: [VendorCatalog] = []
    @State private var selectedCatalogItemId = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        // Event Information
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

                        // Description
                        FormCard(title: "Description") {
                            TextEditor(text: $description)
                                .frame(height: 110)
                                .padding(6)
                                .background(Color.appBackground)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appDivider, lineWidth: 1))
                                .foregroundColor(.appTextPrimary)
                        }

                        // Vendor Partnership
                        FormCard(title: "Vendor Partnership") {
                            Picker("Select Vendor", selection: $selectedVendorId) {
                                Text("No Vendor").tag("")
                                ForEach(vendors) { vendor in
                                    Text(vendor.name).tag(vendor.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.appAccent)
                        }

                        if !selectedVendorId.isEmpty && !catalogItems.isEmpty {
                            FormCard(title: "Vendor Package") {
                                Picker("Select Package", selection: $selectedCatalogItemId) {
                                    Text("No Package").tag("")
                                    ForEach(catalogItems) { item in
                                        Text("\(item.name) (\(FormattingHelper.formatCurrency(item.price)))").tag(item.id)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.appAccent)
                            }
                        }

                        // Capacity
                        FormCard(title: "Capacity") {
                            Stepper(value: $quota, in: 1...1000, step: 10) {
                                HStack {
                                    Text("Event Quota")
                                        .foregroundColor(.appTextPrimary)
                                    Spacer()
                                    Text("\(quota)")
                                        .fontWeight(.bold)
                                        .foregroundColor(.appAccent)
                                }
                            }
                            .tint(.appAccent)
                        }

                        if !errorMessage.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.appRed)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.appRed)
                            }
                            .padding()
                            .background(Color.appRed.opacity(0.08))
                            .cornerRadius(10)
                        }

                        Button(action: createEvent) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Create Event")
                                        .fontWeight(.bold)
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
            .navigationTitle("Create Event")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appAccent)
                }
            }
            .onAppear {
                FirebaseService.shared.getAllVendors { list, _ in
                    if let list = list { self.vendors = list }
                }
            }
            .onChange(of: selectedVendorId) { newVendorId in
                selectedCatalogItemId = ""
                if !newVendorId.isEmpty {
                    FirebaseService.shared.getVendorCatalog(vendorId: newVendorId) { items, _ in
                        if let items = items {
                            self.catalogItems = items
                            if let first = items.first { self.selectedCatalogItemId = first.id }
                        }
                    }
                } else {
                    self.catalogItems = []
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
            createdAt: Date(),
            vendorId: selectedVendorId.isEmpty ? nil : selectedVendorId
        )
        viewModel.createEvent(event: event) { success, error in
            if success {
                if !selectedVendorId.isEmpty && !selectedCatalogItemId.isEmpty {
                    let amount = catalogItems.first(where: { $0.id == selectedCatalogItemId })?.price ?? 0.0
                    let invoice = Invoice(
                        id: UUID().uuidString,
                        eventId: event.id,
                        vendorId: selectedVendorId,
                        amount: amount,
                        status: .pending,
                        dueDate: Date().addingTimeInterval(86400 * 7),
                        createdAt: Date(),
                        paidAt: nil,
                        notes: "Tagihan untuk paket: \(title)"
                    )
                    FirebaseService.shared.createInvoice(invoice) { _, _ in
                        DispatchQueue.main.async { isLoading = false; dismiss() }
                    }
                } else {
                    isLoading = false; dismiss()
                }
            } else {
                isLoading = false
                errorMessage = error ?? "Failed to create event"
            }
        }
    }
}

// MARK: - Form Helper Views

struct FormCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.appTextSecondary)
                .padding(.horizontal, 4)
            VStack {
                content
            }
            .padding()
            .background(Color.appCard)
            .cornerRadius(14)
        }
    }
}

struct UIFormField<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.appAccent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                content
            }
        }
    }
}

// MARK: - Event Management

struct EventManagementView: View {
    let event: Event
    @ObservedObject var viewModel: PanitiaViewModel
    @State private var showAttendanceScanner = false
    @State private var showEventRecap = false
    @State private var showLiveMonitoring = false
    @State private var showEventInvoices = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {

                    // Event Info Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Event Details")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.appTextSecondary)

                        VStack(spacing: 0) {
                            MgmtInfoRow(icon: "textformat", label: "Title", value: event.title)
                            Divider().background(Color.appDivider).padding(.leading, 44)
                            MgmtInfoRow(icon: "calendar", label: "Date", value: event.eventDate.formatted(date: .abbreviated, time: .shortened))
                            Divider().background(Color.appDivider).padding(.leading, 44)
                            MgmtInfoRow(icon: "mappin.and.ellipse", label: "Location", value: event.location)
                            Divider().background(Color.appDivider).padding(.leading, 44)
                            MgmtInfoRow(icon: "person.2.fill", label: "Participants", value: "\(event.registeredCount)/\(event.quota)")
                        }
                        .background(Color.appCard)
                        .cornerRadius(14)
                    }

                    // Management Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Management")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.appTextSecondary)

                        VStack(spacing: 0) {
                            MgmtActionRow(icon: "qrcode.viewfinder", label: "Check-in (QR Scan)", color: .appAccent) {
                                showAttendanceScanner = true
                            }
                            Divider().background(Color.appDivider).padding(.leading, 44)
                            MgmtActionRow(icon: "chart.bar.xaxis", label: "Live Monitoring Dashboard", color: .appGreen) {
                                showLiveMonitoring = true
                            }
                            Divider().background(Color.appDivider).padding(.leading, 44)
                            MgmtActionRow(icon: "doc.text.magnifyingglass", label: "View Event Recap", color: .appAccent) {
                                showEventRecap = true
                            }
                            Divider().background(Color.appDivider).padding(.leading, 44)
                            MgmtActionRow(icon: "doc.richtext.fill", label: "Bills & Invoices", color: .appOrange) {
                                showEventInvoices = true
                            }
                        }
                        .background(Color.appCard)
                        .cornerRadius(14)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Event Management")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAttendanceScanner) {
            QRScannerView(eventId: event.id, viewModel: viewModel)
        }
        .sheet(isPresented: $showLiveMonitoring) {
            LiveMonitoringView(event: event)
        }
        .sheet(isPresented: $showEventRecap) {
            EventRecapView(eventId: event.id, viewModel: viewModel)
        }
        .sheet(isPresented: $showEventInvoices) {
            EventBillsView(eventId: event.id)
        }
    }
}

struct MgmtInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.appAccent)
                .frame(width: 28)
            Text(label)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.appTextSecondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding()
    }
}

struct MgmtActionRow: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 28)
                Text(label)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            .padding()
        }
    }
}

// MARK: - Bills & Invoices

struct EventBillsView: View {
    let eventId: String
    @Environment(\.dismiss) var dismiss
    @State private var invoices: [Invoice] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var actionError = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                Group {
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.appAccent)
                            Text("Loading invoices...")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                    } else if !errorMessage.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.appOrange)
                            Text(errorMessage)
                                .foregroundColor(.appRed)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    } else if invoices.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "doc.richtext")
                                .font(.system(size: 40))
                                .foregroundColor(.appAccent.opacity(0.5))
                            Text("No bills or invoices for this event.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.appTextSecondary)
                        }
                    } else {
                        ScrollView {
                            if !actionError.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.appRed)
                                    Text(actionError)
                                        .font(.caption)
                                        .foregroundColor(.appRed)
                                }
                                .padding()
                                .background(Color.appRed.opacity(0.08))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }

                            LazyVStack(spacing: 12) {
                                ForEach(invoices) { invoice in
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Text("Invoice #\(invoice.id.prefix(8))")
                                                .font(.system(.headline, design: .rounded))
                                                .foregroundColor(.appTextPrimary)
                                            Spacer()
                                            Text(statusLabel(invoice.status))
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(statusColor(invoice.status).opacity(0.15))
                                                .foregroundColor(statusColor(invoice.status))
                                                .cornerRadius(6)
                                        }

                                        Divider().background(Color.appDivider)

                                        HStack {
                                            Label {
                                                Text(FormattingHelper.formatCurrency(invoice.amount))
                                                    .font(.system(.subheadline, design: .rounded))
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.appTextPrimary)
                                            } icon: {
                                                Image(systemName: "banknote.fill")
                                                    .foregroundColor(.appAccent)
                                            }
                                            Spacer()
                                            Label {
                                                Text(invoice.dueDate.formatted(date: .abbreviated, time: .omitted))
                                                    .font(.caption)
                                                    .foregroundColor(.appTextSecondary)
                                            } icon: {
                                                Image(systemName: "calendar")
                                                    .foregroundColor(.appAccent)
                                            }
                                        }

                                        if let notes = invoice.notes {
                                            Text(notes)
                                                .font(.caption)
                                                .foregroundColor(.appTextSecondary)
                                        }

                                        if invoice.status == .unpaid {
                                            HStack {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.appGreen)
                                                        .font(.caption)
                                                    Text("Accepted by Vendor")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.appGreen)
                                                }
                                                Spacer()
                                                Button(action: { payBill(invoice: invoice) }) {
                                                    Text("Pay Bill")
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                        .padding(.horizontal, 14)
                                                        .padding(.vertical, 6)
                                                        .background(Color.appAccent)
                                                        .foregroundColor(.white)
                                                        .cornerRadius(8)
                                                }
                                            }
                                            .padding(.top, 2)
                                        }
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
            .navigationTitle("Bills & Invoices")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.appAccent)
                }
            }
            .onAppear(perform: loadInvoices)
        }
    }

    private func loadInvoices() {
        isLoading = true
        errorMessage = ""
        FirebaseService.shared.getEventInvoices(eventId: eventId) { items, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error { errorMessage = error }
                else if let items = items { invoices = items }
            }
        }
    }

    private func payBill(invoice: Invoice) {
        actionError = ""
        FirebaseService.shared.updateInvoiceStatus(invoiceId: invoice.id, status: .paid) { success, error in
            DispatchQueue.main.async {
                if success { loadInvoices() }
                else { actionError = error ?? "Failed to update payment." }
            }
        }
    }

    private func statusLabel(_ status: InvoiceStatus) -> String {
        switch status {
        case .pending:   return "Pending"
        case .unpaid:    return "Accepted"
        case .paid:      return "Paid"
        case .overdue:   return "Overdue"
        case .cancelled: return "Cancelled"
        }
    }

    private func statusColor(_ status: InvoiceStatus) -> Color {
        switch status {
        case .pending:   return .appAccent
        case .unpaid:    return .appGreen
        case .paid:      return .appTextSecondary
        case .overdue:   return .appOrange
        case .cancelled: return .appRed
        }
    }
}

// MARK: - QR Scanner

struct QRScannerView: View {
    let eventId: String
    @ObservedObject var viewModel: PanitiaViewModel
    @Environment(\.dismiss) var dismiss
    @State private var scannedCode = ""
    @State private var message = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 20) {

                    Text("Point camera at attendee's QR Code")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    ZStack {
                        #if targetEnvironment(simulator)
                        VStack(spacing: 12) {
                            Image(systemName: "camera.metering.none")
                                .font(.system(size: 48))
                                .foregroundColor(.appAccent.opacity(0.5))
                            Text("Camera not available in Simulator")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.appTextSecondary)
                            Text("Use manual input below to test.")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .background(Color.appCard)
                        .cornerRadius(16)
                        #else
                        ScannerView { result in
                            switch result {
                            case .success(let code):
                                self.scannedCode = code
                                self.checkAttendance()
                            case .failure:
                                self.message = "Failed to open camera or access denied."
                            }
                        }
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appAccent, lineWidth: 2)
                        )
                        #endif
                    }

                    // Manual input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Manual Entry")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                        HStack {
                            Image(systemName: "keyboard")
                                .foregroundColor(.appAccent)
                            TextField("Enter ticket ID or Peserta ID", text: $scannedCode)
                                .foregroundColor(.appTextPrimary)
                        }
                        .padding()
                        .background(Color.appCard)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appDivider, lineWidth: 1))
                    }

                    if !message.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: message.contains("successful") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(message.contains("successful") ? .appGreen : .appRed)
                            Text(message)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(message.contains("successful") ? .appGreen : .appRed)
                        }
                        .padding()
                        .background((message.contains("successful") ? Color.appGreen : Color.appRed).opacity(0.08))
                        .cornerRadius(12)
                    }

                    Button(action: checkAttendance) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Confirm Check-in")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appAccent)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Check-in")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appAccent)
                }
            }
        }
    }

    private func checkAttendance() {
        viewModel.recordAttendance(eventId: eventId, scannedCode: scannedCode) { success in
            message = success ? "Check-in successful!" : "Invalid ticket or already checked in"
            scannedCode = ""
        }
    }
}

// MARK: - Event Recap

struct EventRecapView: View {
    let eventId: String
    @ObservedObject var viewModel: PanitiaViewModel
    @State private var recap: EventRecap?

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                Group {
                    if let recap = recap {
                        ScrollView {
                            VStack(spacing: 14) {

                                // Header
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(recap.title)
                                            .font(.system(.headline, design: .rounded))
                                            .fontWeight(.bold)
                                            .foregroundColor(.appDeep)
                                        Text("Event Recap")
                                            .font(.caption)
                                            .foregroundColor(.appDeep.opacity(0.7))
                                    }
                                    Spacer()
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.title2)
                                        .foregroundColor(.appDeep)
                                }
                                .padding(18)
                                .background(Color.appPrimary)
                                .cornerRadius(16)

                                // Stats grid
                                HStack(spacing: 12) {
                                    DashStatCard(icon: "person.fill.checkmark", title: "Attended", value: "\(recap.attendance.count)")
                                    DashStatCard(icon: "bubble.left.and.bubble.right.fill", title: "Feedbacks", value: "\(recap.feedbackCount)")
                                }

                                // Rating
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Average Rating")
                                        .font(.system(.caption, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.appTextSecondary)

                                    HStack {
                                        Text(String(repeating: "★", count: Int(recap.averageRating.rounded())) +
                                             String(repeating: "☆", count: 5 - Int(recap.averageRating.rounded())))
                                            .font(.title)
                                            .foregroundColor(.appOrange)
                                        Text(String(format: "%.1f / 5.0", recap.averageRating))
                                            .font(.system(.body, design: .rounded))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.appTextPrimary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color.appCard)
                                    .cornerRadius(14)
                                }
                            }
                            .padding()
                        }
                    } else {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.appAccent)
                            Text("Loading recap...")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                        .onAppear {
                            viewModel.getEventRecap(eventId: eventId) { r in
                                self.recap = r
                            }
                        }
                    }
                }
            }
            .navigationTitle("Event Recap")
        }
    }
}

// MARK: - Attendance View

struct AttendanceView: View {
    @ObservedObject var viewModel: PanitiaViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                Group {
                    if viewModel.attendance.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 52))
                                .foregroundColor(.appAccent.opacity(0.4))
                            Text("No attendance records yet")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.appTextSecondary)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(viewModel.attendance.keys.sorted(), id: \.self) { eventId in
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "calendar.badge.checkmark")
                                                .foregroundColor(.appAccent)
                                            Text("Event: \(eventId)")
                                                .font(.system(.subheadline, design: .rounded))
                                                .fontWeight(.semibold)
                                                .foregroundColor(.appTextPrimary)
                                            Spacer()
                                            Text("\(viewModel.attendance[eventId]?.count ?? 0) checked in")
                                                .font(.caption)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                        Divider().background(Color.appDivider)
                                        ForEach(viewModel.attendance[eventId] ?? [], id: \.self) { pesertaId in
                                            HStack(spacing: 8) {
                                                Circle()
                                                    .fill(Color.appPrimary)
                                                    .frame(width: 28, height: 28)
                                                    .overlay(
                                                        Image(systemName: "person.fill")
                                                            .font(.caption)
                                                            .foregroundColor(.appDeep)
                                                    )
                                                Text(pesertaId)
                                                    .font(.system(.caption, design: .monospaced))
                                                    .foregroundColor(.appTextPrimary)
                                            }
                                        }
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
            .navigationTitle("Attendance")
        }
    }
}

// MARK: - Panitia Profile

struct PanitiaProfileView: View {
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
                                    Image(systemName: "person.badge.shield.checkmark.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.appDeep)
                                )
                            Text(authManager.currentUser?.name ?? "Panitia")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.appTextPrimary)
                            Text("Panitia")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
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
                        }
                        .background(Color.appCard)
                        .cornerRadius(16)

                        Button(action: { authManager.logout() }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Logout")
                                    .fontWeight(.bold)
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
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Live Monitoring

struct LiveMonitoringView: View {
    let event: Event
    @State private var checkInCount: Int = 0
    @State private var listener: ListenerRegistration? = nil
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {

                        // Event title card
                        VStack(spacing: 6) {
                            Text(event.title)
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.appDeep)
                                .multilineTextAlignment(.center)
                            Text("Live Attendance Monitor")
                                .font(.subheadline)
                                .foregroundColor(.appDeep.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(18)
                        .background(Color.appPrimary)
                        .cornerRadius(16)

                        // Big Counter Card
                        VStack(spacing: 14) {
                            Text("\(checkInCount)")
                                .font(.system(size: 80, weight: .bold, design: .rounded))
                                .foregroundColor(.appAccent)

                            Text("Checked In")
                                .font(.headline)
                                .foregroundColor(.appTextSecondary)

                            Divider()
                                .background(Color.appDivider)
                                .padding(.horizontal, 30)

                            HStack(spacing: 40) {
                                VStack(spacing: 4) {
                                    Text("\(event.registeredCount)")
                                        .font(.system(.title2, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.appTextPrimary)
                                    Text("Registered")
                                        .font(.caption)
                                        .foregroundColor(.appTextSecondary)
                                }

                                VStack(spacing: 4) {
                                    let percent = event.registeredCount > 0 ? (Double(checkInCount) / Double(event.registeredCount)) * 100 : 0
                                    Text(String(format: "%.1f%%", percent))
                                        .font(.system(.title2, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.appTextPrimary)
                                    Text("Attendance Rate")
                                        .font(.caption)
                                        .foregroundColor(.appTextSecondary)
                                }
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(Color.appCard)
                        .cornerRadius(18)
                        .shadow(color: Color.appAccent.opacity(0.10), radius: 10, x: 0, y: 5)

                        // Live feed indicator
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.appRed)
                                .frame(width: 8, height: 8)
                            Text("LIVE FEED ACTIVE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.appRed)
                                .tracking(1.5)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 14)
                        .background(Color.appRed.opacity(0.08))
                        .cornerRadius(20)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.appAccent)
                }
            }
            .onAppear {
                listener = FirebaseService.shared.listenToLiveAttendance(eventId: event.id) { count in
                    self.checkInCount = count
                }
            }
            .onDisappear {
                listener?.remove()
            }
        }
    }
}

#Preview {
    PanitiaMainView()
        .environmentObject(AuthManager())
}
