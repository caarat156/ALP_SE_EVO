import SwiftUI

struct PesertaMainView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = PesertaViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            PesertaHomeView(viewModel: viewModel)
                .tabItem {
                    Text("Home")
                }
                .tag(0)
            
            // Events Tab
            PesertaEventsView(viewModel: viewModel)
                .tabItem {
                    Text("Events")
                }
                .tag(1)
            
            // Tickets Tab
            PesertaTicketsView(viewModel: viewModel)
                .tabItem {
                    Text("Tickets")
                }
                .tag(2)
            
            // Profile Tab
            PesertaProfileView()
                .tabItem {
                    Text("Profile")
                }
                .tag(3)
        }
        .onAppear {
            if let userId = authManager.currentUser?.id {
                viewModel.fetchRegisteredEvents(pesertaId: userId)
                viewModel.fetchTickets(pesertaId: userId)
            }
        }
    }
}

struct PesertaHomeView: View {
    @ObservedObject var viewModel: PesertaViewModel
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Welcome")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hello, \(authManager.currentUser?.name ?? "User")!")
                                .font(.headline)
                            Text("You have \(viewModel.registeredEvents.count) registered events")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section(header: Text("Recent Tickets")) {
                        if viewModel.tickets.isEmpty {
                            Text("No tickets yet")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(viewModel.tickets.prefix(3)) { ticket in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ticket ID: \(ticket.id.prefix(8))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Status: \(ticket.status.rawValue.capitalized)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct PesertaEventsView: View {
    @ObservedObject var viewModel: PesertaViewModel
    @State private var showAvailableEvents = false
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    if viewModel.registeredEvents.isEmpty {
                        Text("No registered events yet")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(viewModel.registeredEvents) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(.headline)
                                    Text(event.eventDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(event.location)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Button(action: { showAvailableEvents = true }) {
                    Text("Register for New Event")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                }
            }
            .navigationTitle("Events")
            .sheet(isPresented: $showAvailableEvents) {
                AvailableEventsView(viewModel: viewModel)
            }
        }
    }
}

struct AvailableEventsView: View {
    @ObservedObject var viewModel: PesertaViewModel
    @Environment(\.dismiss) var dismiss
    @State private var allEvents: [Event] = []
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            List {
                ForEach(allEvents.filter { event in
                    !viewModel.registeredEvents.contains(where: { registeredEvent in registeredEvent.id == event.id })
                }) { event in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.headline)
                            Text("Quota: \(event.registeredCount)/\(event.quota)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            registerForEvent(event)
                        }) {
                            Text("Register")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .navigationTitle("Available Events")
            .onAppear {
                loadAvailableEvents()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func loadAvailableEvents() {
        FirebaseService.shared.getAllEvents { events, _ in
            allEvents = events ?? []
        }
    }
    
    private func registerForEvent(_ event: Event) {
        guard let userId = authManager.currentUser?.id else { return }
        viewModel.registerEvent(pesertaId: userId, eventId: event.id, eventTitle: event.title) { success, _ in
            if success {
                dismiss()
            }
        }
    }
}

struct EventDetailView: View {
    let event: Event
    @State private var showFeedbackForm = false
    
    var body: some View {
        ScrollView {
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
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    Text(event.description)
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Status")
                        .font(.headline)
                    Text(event.status.rawValue.capitalized)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(statusColor(event.status).opacity(0.1))
                        .foregroundColor(statusColor(event.status))
                        .cornerRadius(4)
                }
                
                if event.status == .completed {
                    Button(action: { showFeedbackForm = true }) {
                        Text("Leave Feedback")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Event Details")
        .sheet(isPresented: $showFeedbackForm) {
            FeedbackFormView(event: event)
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

struct FeedbackFormView: View {
    let event: Event
    @State private var rating = 3
    @State private var comment = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = PesertaViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Rating")) {
                    Stepper(value: $rating, in: 1...5) {
                        HStack {
                            Text("Rate this event")
                            Spacer()
                            Text(String(repeating: "★", count: rating) + String(repeating: "☆", count: 5 - rating))
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }
                
                Section(header: Text("Comment")) {
                    TextEditor(text: $comment)
                        .frame(height: 120)
                }
                
                Button(action: submitFeedback) {
                    Text("Submit Feedback")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .navigationTitle("Event Feedback")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitFeedback() {
        guard let userId = authManager.currentUser?.id else { return }
        let feedback = Feedback(
            id: UUID().uuidString,
            eventId: event.id,
            pesertaId: userId,
            targetId: event.createdBy,
            rating: rating,
            comment: comment,
            type: "panitia",
            createdAt: Date()
        )
        
        viewModel.submitFeedback(feedback: feedback) { success, _ in
            if success {
                dismiss()
            }
        }
    }
}

struct PesertaTicketsView: View {
    @ObservedObject var viewModel: PesertaViewModel
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.tickets.isEmpty {
                    Text("No tickets available")
                        .foregroundColor(.gray)
                } else {
                    ForEach(viewModel.tickets) { ticket in
                        NavigationLink(destination: TicketDetailView(ticket: ticket, viewModel: viewModel)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Event: \(ticket.eventTitle)")
                                    .font(.headline)
                                Text("Status: \(ticket.status.rawValue.capitalized)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("Created: \(ticket.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Tickets")
        }
    }
}

struct TicketDetailView: View {
    let ticket: Ticket
    @ObservedObject var viewModel: PesertaViewModel
    @State private var showQRCode = false
    @State private var showFeedbackForm = false
    @State private var brightness: CGFloat = 0.5
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ticket Details")
                    .font(.headline)
                
                HStack {
                    Text("Ticket ID:")
                    Spacer()
                    Text(ticket.id)
                        .font(.caption)
                        .monospaced()
                }
                
                HStack {
                    Text("Event Name:")
                    Spacer()
                    Text(ticket.eventTitle)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Status:")
                    Spacer()
                    Text(ticket.status.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            if ticket.status == .active {
                Button(action: { showQRCode = true }) {
                    Text("Show QR Code")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            } else if ticket.status == .used {
                Button(action: { showFeedbackForm = true }) {
                    Text("Review Event")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Ticket")
        .sheet(isPresented: $showQRCode) {
            QRCodeDisplayView(ticket: ticket)
        }
        .sheet(isPresented: $showFeedbackForm) {
            if let event = viewModel.registeredEvents.first(where: { $0.id == ticket.eventId }) {
                FeedbackFormView(event: event)
            } else {
                Text("Event data not found.")
            }
        }
    }
}

struct QRCodeDisplayView: View {
    let ticket: Ticket
    @State private var screenBrightness: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("QR Code")
                    .font(.headline)
                    .padding(.top)
                
                // Real QR Code display
                VStack(spacing: 12) {
                    Image(uiImage: QRCodeHelper.shared.generateQRCode(from: ticket.encryptedData))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    
                    Text(ticket.id)
                        .font(.caption)
                        .monospaced()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .border(Color.black)
                
                Text("Please show this QR code to the staff")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .onAppear {
            // Set screen brightness to maximum
            UIScreen.main.brightness = 1.0
        }
    }
}

struct PesertaProfileView: View {
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
                        
                        HStack {
                            Text("Role")
                            Spacer()
                            Text((authManager.currentUser?.role.rawValue ?? "N/A").capitalized)
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
    PesertaMainView()
        .environmentObject(AuthManager())
}
