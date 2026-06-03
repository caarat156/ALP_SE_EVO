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
        
        viewModel.createEvent(event: event) { success, error in
            isLoading = false
            if success {
                dismiss()
            } else {
                errorMessage = error ?? "Failed to create event"
            }
        }
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
                
                ZStack {
                    #if targetEnvironment(simulator)
                    VStack(spacing: 12) {
                        Image(systemName: "camera.metering.none")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Camera not available in Simulator")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Use manual input below to test.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    #else
                    ScannerView { result in
                        switch result {
                        case .success(let code):
                            self.scannedCode = code
                            self.checkAttendance()
                        case .failure(let error):
                            print("Scanner error: \(error)")
                            self.message = "Failed to open camera or access denied."
                        }
                    }
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    #endif
                }
                
                TextField("Or enter ticket ID / Peserta ID manually", text: $scannedCode)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                
                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(message.contains("successful") ? .green : .red)
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
        let decodedCode = scannedCode.base64Decoded() ?? scannedCode
        let parts = decodedCode.split(separator: "|")
        
        let pesertaId: String
        if parts.count >= 3 {
            pesertaId = String(parts[2])
        } else {
            pesertaId = decodedCode
        }
        
        viewModel.recordAttendance(eventId: eventId, pesertaId: pesertaId) { success in
            message = success ? "Check-in successful!" : "Invalid ticket or already checked in"
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
