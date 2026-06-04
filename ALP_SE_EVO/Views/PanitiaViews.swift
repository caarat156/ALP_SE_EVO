import SwiftUI

struct PanitiaMainView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = PanitiaViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            PanitiaDashboardView(viewModel: viewModel)
                .tabItem {
                    Text("Dashboard")
                }
                .tag(0)
            
            // Events Tab
            PanitiaEventsView(viewModel: viewModel)
                .tabItem {
                    Text("Events")
                }
                .tag(1)
            
            // Attendance Tab
            AttendanceView(viewModel: viewModel)
                .tabItem {
                    Text("Attendance")
                }
                .tag(2)
            
            // Profile Tab
            PanitiaProfileView()
                .tabItem {
                    Text("Profile")
                }
                .tag(3)
        }
        .onAppear {
            if let userId = authManager.currentUser?.id {
                viewModel.fetchManagedEvents(panitiaId: userId)
            }
        }
    }
}

struct PanitiaDashboardView: View {
    @ObservedObject var viewModel: PanitiaViewModel
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Event Overview")) {
                        HStack {
                            Text("Total Events")
                            Spacer()
                            Text("\(viewModel.managedEvents.count)")
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text("Active Events")
                            Spacer()
                            Text("\(viewModel.managedEvents.filter { $0.status == .ongoing }.count)")
                                .fontWeight(.bold)
                        }
                    }
                    
                    Section(header: Text("Recent Events")) {
                        if viewModel.managedEvents.isEmpty {
                            Text("No events yet")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(viewModel.managedEvents.prefix(3)) { event in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(.headline)
                                    Text("Participants: \(event.registeredCount)/\(event.quota)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct PanitiaEventsView: View {
    @ObservedObject var viewModel: PanitiaViewModel
    @State private var showCreateEvent = false
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    if viewModel.managedEvents.isEmpty {
                        Text("No events created yet")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(viewModel.managedEvents) { event in
                            NavigationLink(destination: EventManagementView(event: event, viewModel: viewModel)) {
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
                    Text("Create New Event")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                }
            }
            .navigationTitle("Events")
            .sheet(isPresented: $showCreateEvent) {
                CreateEventView(viewModel: viewModel)
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
    
    // Vendor selection
    @State private var selectedVendorItems: [SelectedVendorItem] = []
    @State private var showVendorPicker = false
    
    struct SelectedVendorItem: Identifiable {
        let id = UUID().uuidString
        let catalogItem: VendorCatalog
        let vendor: User
        var quantity: Int
    }
    
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
                    Stepper(value: $quota, in: 1...1000, step: 10) {
                        HStack {
                            Text("Event Quota")
                            Spacer()
                            Text("\(quota)")
                                .fontWeight(.bold)
                        }
                    }
                }
                
                // Vendor Products Section
                Section(header: Text("Vendor Products")) {
                    if selectedVendorItems.isEmpty {
                        Text("No vendor products added")
                            .foregroundColor(.gray)
                            .font(.caption)
                    } else {
                        ForEach(Array(selectedVendorItems.enumerated()), id: \.element.id) { index, item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.catalogItem.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Vendor: \(item.vendor.name)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                HStack {
                                     Text(FormattingHelper.formatCurrency(Double(item.catalogItem.price)))
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text("Qty: \(item.quantity)")
                                        .font(.caption)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            selectedVendorItems.remove(atOffsets: indexSet)
                        }
                    }
                    
                    Button(action: { showVendorPicker = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Vendor Product")
                        }
                        .foregroundColor(.blue)
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
            .navigationTitle("Create Event")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showVendorPicker) {
                VendorItemPickerView(
                    viewModel: viewModel,
                    selectedItems: $selectedVendorItems
                )
            }
        }
    }
    
    private func createEvent() {
        guard let userId = authManager.currentUser?.id else { return }
        isLoading = true
        
        let eventId = UUID().uuidString
        let event = Event(
            id: eventId,
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
        
        // Build EventVendorItem list
        let vendorItems: [EventVendorItem] = selectedVendorItems.map { selected in
            EventVendorItem(
                id: UUID().uuidString,
                eventId: eventId,
                vendorId: selected.catalogItem.vendorId,
                catalogItemId: selected.catalogItem.id,
                vendorName: selected.vendor.name,
                itemName: selected.catalogItem.name,
                itemPrice: selected.catalogItem.price,
                quantity: selected.quantity,
                eventTitle: title,
                createdAt: Date()
            )
        }
        
        if vendorItems.isEmpty {
            viewModel.createEvent(event: event) { success, error in
                isLoading = false
                if success { dismiss() }
                else { errorMessage = error ?? "Failed to create event" }
            }
        } else {
            viewModel.createEventWithVendorItems(event: event, vendorItems: vendorItems) { success, error in
                isLoading = false
                if success { dismiss() }
                else { errorMessage = error ?? "Failed to create event" }
            }
        }
    }
}

// MARK: - Vendor Item Picker
struct VendorItemPickerView: View {
    @ObservedObject var viewModel: PanitiaViewModel
    @Binding var selectedItems: [CreateEventView.SelectedVendorItem]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.allVendors) { vendor in
                    vendorSection(vendor: vendor)
                }
            }
            .navigationTitle("Select Vendor Product")
            .overlay {
                if viewModel.allVendors.isEmpty && viewModel.allCatalogItems.isEmpty {
                    Text("Loading vendors...")
                        .foregroundColor(.gray)
                } else if viewModel.allCatalogItems.isEmpty {
                    Text("No vendor products available")
                        .foregroundColor(.gray)
                }
            }
            .onAppear {
                viewModel.fetchAllVendors()
                viewModel.fetchAllCatalogItems()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    @ViewBuilder
    private func vendorSection(vendor: User) -> some View {
        let vendorItems = viewModel.allCatalogItems.filter { $0.vendorId == vendor.id }
        if !vendorItems.isEmpty {
            Section(header: Text(vendor.name)) {
                ForEach(vendorItems) { item in
                    vendorItemRow(item: item, vendor: vendor)
                }
            }
        }
    }
    
    private func vendorItemRow(item: VendorCatalog, vendor: User) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                Text(FormattingHelper.formatCurrency(Double(item.price)))
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button(action: {
                addItem(item: item, vendor: vendor)
            }) {
                Text("Add")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
    }
    
    private func addItem(item: VendorCatalog, vendor: User) {
        let selected = CreateEventView.SelectedVendorItem(
            catalogItem: item,
            vendor: vendor,
            quantity: 1
        )
        selectedItems.append(selected)
        dismiss()
    }
}

struct EventManagementView: View {
    let event: Event
    @ObservedObject var viewModel: PanitiaViewModel
    @State private var showAttendanceScanner = false
    @State private var showEventRecap = false
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Event Details")) {
                    HStack {
                        Text("Title")
                        Spacer()
                        Text(event.title)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(event.eventDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("Location")
                        Spacer()
                        Text(event.location)
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("Participants")
                        Spacer()
                        Text("\(event.registeredCount)/\(event.quota)")
                            .fontWeight(.semibold)
                    }
                }
                
                Section(header: Text("Vendor Products")) {
                    if viewModel.eventVendorItems.isEmpty {
                        Text("No vendor products used")
                            .foregroundColor(.gray)
                            .font(.caption)
                    } else {
                        ForEach(viewModel.eventVendorItems) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.itemName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Vendor: \(item.vendorName)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                HStack {
                                    Text(FormattingHelper.formatCurrency(Double(item.itemPrice)))
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text("Qty: \(item.quantity)")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Management")) {
                    Button(action: { showAttendanceScanner = true }) {
                        HStack {
                            Text("Check-in (QR Scan)")
                            Spacer()
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Button(action: { showEventRecap = true }) {
                        HStack {
                            Text("View Event Recap")
                            Spacer()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle("Event Management")
        .onAppear {
            viewModel.fetchEventVendorItems(eventId: event.id)
        }
        .sheet(isPresented: $showAttendanceScanner) {
            QRScannerView(eventId: event.id, viewModel: viewModel)
        }
        .sheet(isPresented: $showEventRecap) {
            EventRecapView(eventId: event.id, viewModel: viewModel)
        }
    }
}

struct QRScannerView: View {
    let eventId: String
    @ObservedObject var viewModel: PanitiaViewModel
    @Environment(\.dismiss) var dismiss
    @State private var scannedCode = ""
    @State private var message = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Scan QR Code")
                    .font(.headline)
                    .padding()
                
                ScannerView { result in
                    switch result {
                    case .success(let code):
                        scannedCode = code
                        checkAttendance()
                    case .failure(let error):
                        message = error.localizedDescription
                    }
                }
                .frame(height: 300)
                .cornerRadius(12)
                
                TextField("Or enter ticket ID manually", text: $scannedCode)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                
                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding()
                }
                
                Button(action: checkAttendance) {
                    Text("Confirm Check-in")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Check-in")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func checkAttendance() {
        var pesertaId = scannedCode
        
        // If it's a base64 encoded string from ticket, try to decode it
        if let decodedData = Data(base64Encoded: scannedCode),
           let decodedString = String(data: decodedData, encoding: .utf8) {
            let components = decodedString.components(separatedBy: ":")
            if components.count >= 3 {
                pesertaId = components[2]
            }
        }
        
        viewModel.recordAttendance(eventId: eventId, pesertaId: pesertaId) { success in
            message = success ? "Check-in successful!" : "Invalid ticket"
            scannedCode = ""
        }
    }
}

struct EventRecapView: View {
    let eventId: String
    @ObservedObject var viewModel: PanitiaViewModel
    @State private var recap: EventRecap?
    
    var body: some View {
        NavigationView {
            VStack {
                if let recap = recap {
                    List {
                        Section(header: Text("Event: \(recap.title)")) {
                            HStack {
                                Text("Total Attendance")
                                Spacer()
                                Text("\(recap.attendance.count)")
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text("Feedback Count")
                                Spacer()
                                Text("\(recap.feedbackCount)")
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text("Average Rating")
                                Spacer()
                                HStack {
                                    Text(String(repeating: "★", count: Int(recap.averageRating.rounded())) + String(repeating: "☆", count: 5 - Int(recap.averageRating.rounded())))
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                } else {
                    ProgressView()
                        .onAppear {
                            viewModel.getEventRecap(eventId: eventId) { recap in
                                self.recap = recap
                            }
                        }
                }
            }
            .navigationTitle("Event Recap")
        }
    }
}

struct AttendanceView: View {
    @ObservedObject var viewModel: PanitiaViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.attendance.isEmpty {
                    Text("No attendance records yet")
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(viewModel.attendance.keys.sorted(), id: \.self) { eventId in
                            Section(header: Text("Event: \(eventId)")) {
                                ForEach(viewModel.attendance[eventId] ?? [], id: \.self) { pesertaId in
                                    Text(pesertaId)
                                        .font(.caption)
                                        .monospaced()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Attendance")
        }
    }
}

struct PanitiaProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Profile Information")) {
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
                    }
                    
                    Section {
                        Button(action: logout) {
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
    
    private func logout() {
        authManager.logout()
    }
}

#Preview {
    PanitiaMainView()
        .environmentObject(AuthManager())
}
