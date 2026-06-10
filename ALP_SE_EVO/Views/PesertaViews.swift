import SwiftUI

struct PesertaMainView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = PesertaViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PesertaHomeView(viewModel: viewModel)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            PesertaEventsView(viewModel: viewModel)
                .tabItem { Label("Events", systemImage: "calendar") }
                .tag(1)
            PesertaTicketsView(viewModel: viewModel)
                .tabItem { Label("Tickets", systemImage: "ticket.fill") }
                .tag(2)
            PesertaProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(3)
        }
        .accentColor(.appAccent)
        .onAppear {
            if let userId = authManager.currentUser?.id {
                viewModel.fetchRegisteredEvents(pesertaId: userId)
                viewModel.fetchTickets(pesertaId: userId)
            }
        }
    }
}

// MARK: - Home View

struct PesertaHomeView: View {
    @ObservedObject var viewModel: PesertaViewModel
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Hero Header Card — solid appPrimary
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Hello,")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(.appDeep.opacity(0.8))
                                    Text(authManager.currentUser?.name ?? "User")
                                        .font(.system(.title2, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(.appDeep)
                                }
                                Spacer()
                                Image(systemName: "hand.wave.fill")
                                    .font(.title)
                                    .foregroundColor(.appDeep)
                            }
                            
                            Divider()
                                .background(Color.appDivider)
                                .padding(.vertical, 2)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.appDeep)
                                Text("Registered for \(viewModel.registeredEvents.count) event(s)")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundColor(.appDeep)
                            }
                        }
                        .padding(20)
                        .background(Color.appPrimary)
                        .cornerRadius(18)
                        .shadow(color: Color.appAccent.opacity(0.20), radius: 8, x: 0, y: 4)
                        
                        // Recent Tickets
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Tickets")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                            
                            if viewModel.tickets.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "ticket")
                                        .font(.system(size: 38))
                                        .foregroundColor(.appAccent.opacity(0.5))
                                    Text("No tickets yet")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(.appTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 28)
                                .background(Color.appCard)
                                .cornerRadius(14)
                            } else {
                                ForEach(viewModel.tickets.prefix(3)) { ticket in
                                    NavigationLink(destination: TicketDetailView(ticket: ticket, viewModel: viewModel)) {
                                        HStack(spacing: 14) {
                                            Circle()
                                                .fill(Color.appPrimary)
                                                .frame(width: 46, height: 46)
                                                .overlay(
                                                    Image(systemName: "ticket.fill")
                                                        .foregroundColor(.appDeep)
                                                )
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Ticket ID: \(String(ticket.id.prefix(8)))")
                                                    .font(.system(.body, design: .rounded))
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.appTextPrimary)
                                                Text("Status: \(ticket.status.rawValue.capitalized)")
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundColor(ticket.status == .active ? .appGreen : .appTextSecondary)
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
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}

// MARK: - Events View

struct PesertaEventsView: View {
    @ObservedObject var viewModel: PesertaViewModel
    @State private var showAvailableEvents = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.registeredEvents.isEmpty {
                        Spacer()
                        VStack(spacing: 14) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 56))
                                .foregroundColor(.appAccent)
                            Text("No registered events yet")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                            Text("Tap the button below to find events.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(viewModel.registeredEvents) { event in
                                    NavigationLink(destination: EventDetailView(event: event, viewModel: viewModel)) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            HStack {
                                                Text(event.title)
                                                    .font(.system(.headline, design: .rounded))
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.appTextPrimary)
                                                Spacer()
                                                Text(event.status.rawValue.capitalized)
                                                    .font(.system(.caption2, design: .rounded))
                                                    .fontWeight(.bold)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.appPrimary.opacity(0.35))
                                                    .foregroundColor(.appDeep)
                                                    .cornerRadius(6)
                                            }
                                            
                                            Divider().background(Color.appDivider)
                                            
                                            HStack(spacing: 14) {
                                                Label {
                                                    Text(event.eventDate.formatted(date: .abbreviated, time: .shortened))
                                                        .font(.system(.caption, design: .rounded))
                                                        .foregroundColor(.appTextSecondary)
                                                } icon: {
                                                    Image(systemName: "calendar")
                                                        .foregroundColor(.appAccent)
                                                }
                                                Label {
                                                    Text(event.location)
                                                        .font(.system(.caption, design: .rounded))
                                                        .foregroundColor(.appTextSecondary)
                                                } icon: {
                                                    Image(systemName: "mappin.and.ellipse")
                                                        .foregroundColor(.appAccent)
                                                }
                                            }
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
                    
                    Button(action: { showAvailableEvents = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.appDeep)
                            Text("Register for New Event")
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
            .navigationTitle("My Events")
            .sheet(isPresented: $showAvailableEvents) {
                AvailableEventsView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Available Events Sheet

struct AvailableEventsView: View {
    @ObservedObject var viewModel: PesertaViewModel
    @Environment(\.dismiss) var dismiss
    @State private var allEvents: [Event] = []
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(allEvents.filter { event in
                            !viewModel.registeredEvents.contains(where: { $0.id == event.id })
                        }) { event in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundColor(.appTextPrimary)
                                    Text("Quota: \(event.registeredCount)/\(event.quota)")
                                        .font(.caption)
                                        .foregroundColor(.appTextSecondary)
                                }
                                Spacer()
                                Button(action: { registerForEvent(event) }) {
                                    Text("Register")
                                        .font(.system(.caption, design: .rounded))
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.appAccent)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(Color.appCard)
                            .cornerRadius(12)
                            .shadow(color: Color.appAccent.opacity(0.06), radius: 3, x: 0, y: 2)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Available Events")
            .onAppear { loadAvailableEvents() }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.appAccent)
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
        viewModel.registerEvent(pesertaId: userId, eventId: event.id) { success, _ in
            if success { dismiss() }
        }
    }
}

// MARK: - Event Detail

struct EventDetailView: View {
    let event: Event
    @ObservedObject var viewModel: PesertaViewModel
    @State private var showFeedbackForm = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Header card
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.title)
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.appDeep)
                        
                        HStack(spacing: 14) {
                            Label {
                                Text(event.eventDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.appTextSecondary)
                            } icon: {
                                Image(systemName: "calendar").foregroundColor(.appAccent)
                            }
                            Label {
                                Text(event.location)
                                    .font(.caption)
                                    .foregroundColor(.appTextSecondary)
                            } icon: {
                                Image(systemName: "mappin.and.ellipse").foregroundColor(.appAccent)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appPrimary)
                    .cornerRadius(16)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.appTextPrimary)
                        Text(event.description)
                            .font(.body)
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding()
                    .background(Color.appCard)
                    .cornerRadius(14)
                    
                    // Status badge
                    HStack {
                        Text("Event Status")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                        Text(event.status.rawValue.capitalized)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(statusBgColor(event.status))
                            .foregroundColor(statusFgColor(event.status))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.appCard)
                    .cornerRadius(14)
                    
                    if event.status == .completed && viewModel.hasAttendedEvent(eventId: event.id) {
                        Button(action: { showFeedbackForm = true }) {
                            HStack {
                                Image(systemName: "star.bubble.fill")
                                Text("Leave Feedback")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appAccent)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFeedbackForm) {
            FeedbackFormView(event: event)
        }
    }
    
    private func statusBgColor(_ status: EventStatus) -> Color {
        switch status {
        case .upcoming:  return Color.appPrimary.opacity(0.35)
        case .ongoing:   return Color.appOrange.opacity(0.15)
        case .completed: return Color.appGreen.opacity(0.15)
        case .cancelled: return Color.appRed.opacity(0.15)
        }
    }
    
    private func statusFgColor(_ status: EventStatus) -> Color {
        switch status {
        case .upcoming:  return .appDeep
        case .ongoing:   return .appOrange
        case .completed: return .appGreen
        case .cancelled: return .appRed
        }
    }
}

// MARK: - Feedback Form

struct FeedbackFormView: View {
    let event: Event
    @State private var rating = 3
    @State private var comment = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = PesertaViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    
                    // Rating section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rating")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.appTextPrimary)
                        
                        Stepper(value: $rating, in: 1...5) {
                            HStack {
                                Text("Rate this event")
                                    .foregroundColor(.appTextPrimary)
                                Spacer()
                                Text(String(repeating: "★", count: rating) + String(repeating: "☆", count: 5 - rating))
                                    .foregroundColor(.appOrange)
                                    .font(.title3)
                            }
                        }
                    }
                    .padding()
                    .background(Color.appCard)
                    .cornerRadius(14)
                    
                    // Comment section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Comment")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.appTextPrimary)
                        TextEditor(text: $comment)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color.appBackground)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appDivider, lineWidth: 1))
                    }
                    .padding()
                    .background(Color.appCard)
                    .cornerRadius(14)
                    
                    Button(action: submitFeedback) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Submit Feedback")
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
            .navigationTitle("Event Feedback")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appAccent)
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
            if success { dismiss() }
        }
    }
}

// MARK: - Tickets List

struct PesertaTicketsView: View {
    @ObservedObject var viewModel: PesertaViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                Group {
                    if viewModel.tickets.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 54))
                                .foregroundColor(.appAccent.opacity(0.5))
                            Text("No tickets available")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.appTextSecondary)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.tickets) { ticket in
                                    NavigationLink(destination: TicketDetailView(ticket: ticket, viewModel: viewModel)) {
                                        HStack(spacing: 14) {
                                            Circle()
                                                .fill(Color.appPrimary)
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    Image(systemName: "ticket.fill")
                                                        .foregroundColor(.appDeep)
                                                )
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(viewModel.getEventTitle(for: ticket.eventId))
                                                    .font(.system(.body, design: .rounded))
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.appTextPrimary)
                                                Text("Status: \(ticket.status.rawValue.capitalized)")
                                                    .font(.caption)
                                                    .foregroundColor(ticket.status == .active ? .appGreen : .appTextSecondary)
                                                Text(ticket.createdAt.formatted(date: .abbreviated, time: .shortened))
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
                }
            }
            .navigationTitle("My Tickets")
        }
    }
}

// MARK: - Ticket Detail (premium card)

struct TicketDetailView: View {
    let ticket: Ticket
    @ObservedObject var viewModel: PesertaViewModel
    @State private var showQRCode = false
    
    init(ticket: Ticket, viewModel: PesertaViewModel) {
        self.ticket = ticket
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 22) {
                VStack(spacing: 0) {
                    // Header — solid appPrimary
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.getEventTitle(for: ticket.eventId).uppercased())
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.appDeep)
                            Text("E-TICKET ENTRY PASS")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.appDeep.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.appDeep)
                    }
                    .padding(22)
                    .background(Color.appPrimary)
                    
                    // Details
                    VStack(spacing: 14) {
                        DetailRow(icon: "number", label: "Ticket ID", value: String(ticket.id.prefix(12)))
                        DetailRow(icon: "info.circle", label: "Status", value: ticket.status.rawValue.capitalized, isStatus: true)
                        DetailRow(icon: "calendar.badge.clock", label: "Issue Date", value: ticket.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    .padding(22)
                    .background(Color.appCard)
                    
                    // Dashed separator
                    HStack(spacing: 4) {
                        ForEach(0..<22) { _ in
                            Line()
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .frame(width: 7, height: 1)
                                .foregroundColor(Color.appDivider)
                        }
                    }
                    .background(Color.appCard)
                    .padding(.horizontal)
                    
                    // Footer button
                    VStack {
                        if ticket.status == .active {
                            Button(action: { showQRCode = true }) {
                                HStack {
                                    Image(systemName: "qrcode").font(.headline)
                                    Text("Display QR Code")
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.appAccent)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.appAccent.opacity(0.3), radius: 6, x: 0, y: 3)
                            }
                        } else {
                            HStack {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.appRed)
                                Text("This ticket is no longer active")
                                    .foregroundColor(.appTextSecondary)
                                    .font(.subheadline)
                            }
                            .padding()
                        }
                    }
                    .padding(22)
                    .background(Color.appCard)
                }
                .cornerRadius(18)
                .shadow(color: Color.appAccent.opacity(0.10), radius: 12, x: 0, y: 6)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 20)
        }
        .navigationTitle("Ticket Pass")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showQRCode) {
            QRCodeDisplayView(ticket: ticket)
        }
    }
}

// MARK: - Reusable Detail Row

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    var isStatus: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.appAccent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                Text(value)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(isStatus ? (value.lowercased() == "active" ? .appGreen : .appRed) : .appTextPrimary)
            }
            Spacer()
        }
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

// MARK: - QR Code Display View (dark scanner-friendly)

struct QRCodeDisplayView: View {
    let ticket: Ticket
    @State private var originalBrightness: CGFloat = 0.5
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Solid deep blue backdrop — best contrast for QR scanning
            Color.appDeep.ignoresSafeArea()
            
            VStack(spacing: 28) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 6)
                    .padding(.top, 12)
                
                Text("SCAN ENTRANCE PASS")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color.appPrimary.opacity(0.9))
                    .tracking(2)
                
                VStack(spacing: 14) {
                    if let qrImage = ticket.encryptedData.generateQRCode() {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 230, height: 230)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.appPrimary.opacity(0.5), radius: 16, x: 0, y: 0)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.appOrange)
                            Text("QR Code generation failed")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(width: 260, height: 260)
                    }
                    
                    Text("Ticket ID: \(String(ticket.id.prefix(16)))...")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color.appPrimary.opacity(0.7))
                }
                .padding()
                
                VStack(spacing: 6) {
                    Text("Maximized Screen Brightness")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appPrimary)
                    Text("Show this screen to the event check-in scanner.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Button(action: { dismiss() }) {
                    Text("Done")
                        .fontWeight(.bold)
                        .foregroundColor(.appDeep)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            originalBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
        }
        .onDisappear {
            UIScreen.main.brightness = originalBrightness
        }
    }
}

// MARK: - Profile View

struct PesertaProfileView: View {
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
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.appDeep)
                                )
                            Text(authManager.currentUser?.name ?? "User")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.appTextPrimary)
                            Text((authManager.currentUser?.role.rawValue ?? "").capitalized)
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
                            Divider().background(Color.appDivider).padding(.leading, 54)
                            ProfileInfoRow(icon: "person.badge.key.fill", label: "Role", value: (authManager.currentUser?.role.rawValue ?? "N/A").capitalized)
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

struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 14) {
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
        }
        .padding()
    }
}

#Preview {
    PesertaMainView()
        .environmentObject(AuthManager())
}
