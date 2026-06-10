import SwiftUI

// MARK: - Main Tab Container

struct VendorMainView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = VendorViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            VendorCatalogView(viewModel: viewModel)
                .tabItem { Label("Catalog", systemImage: "briefcase.fill") }
                .tag(0)

            VendorInvoicesView(viewModel: viewModel)
                .tabItem { Label("Invoices", systemImage: "doc.text.below.ecg.fill") }
                .tag(1)

            VendorProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(2)
        }
        .accentColor(.appAccent)
        .onAppear {
            if let userId = authManager.currentUser?.id {
                viewModel.fetchCatalog(vendorId: userId)
                viewModel.fetchInvoices(vendorId: userId)
            }
        }
    }
}

// MARK: - Catalog View

struct VendorCatalogView: View {
    @ObservedObject var viewModel: VendorViewModel
    @EnvironmentObject var authManager: AuthManager
    @State private var showAddItem = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView().tint(.appAccent)
                            Text("Loading catalog...").font(.caption).foregroundColor(.appTextSecondary)
                        }
                        Spacer()
                    } else if viewModel.catalogItems.isEmpty {
                        Spacer()
                        VStack(spacing: 14) {
                            Image(systemName: "briefcase.fill")
                                .font(.system(size: 54))
                                .foregroundColor(.appAccent.opacity(0.5))
                            Text("No catalog items yet")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.catalogItems) { item in
                                    NavigationLink(destination: CatalogItemDetailView(item: item)) {
                                        HStack(spacing: 14) {
                                            Circle()
                                                .fill(Color.appPrimary)
                                                .frame(width: 46, height: 46)
                                                .overlay(
                                                    Image(systemName: "cube.box.fill")
                                                        .foregroundColor(.appDeep)
                                                )
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.name)
                                                    .font(.system(.body, design: .rounded))
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.appTextPrimary)
                                                HStack(spacing: 10) {
                                                    Text(FormattingHelper.formatCurrency(item.price))
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.appAccent)
                                                    Text("Qty: \(item.quantity)")
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

                    Button(action: { showAddItem = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill").foregroundColor(.appDeep)
                            Text("Add New Item").fontWeight(.bold).foregroundColor(.appDeep)
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
            .navigationTitle("My Catalog")
            .sheet(isPresented: $showAddItem) {
                AddCatalogItemView(viewModel: viewModel)
                    .environmentObject(authManager)
            }
        }
    }
}

// MARK: - Add Catalog Item

struct AddCatalogItemView: View {
    @ObservedObject var viewModel: VendorViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager

    @State private var name = ""
    @State private var description = ""
    @State private var price = ""
    @State private var quantity = 1
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        VendorFormCard(title: "Item Information") {
                            VStack(spacing: 12) {
                                VendorFormField(label: "Item Name", icon: "cube.box") {
                                    TextField("Enter item name", text: $name)
                                        .foregroundColor(.appTextPrimary)
                                }
                                Divider().background(Color.appDivider)
                                VendorFormField(label: "Description", icon: "text.alignleft") {
                                    TextField("Enter description", text: $description)
                                        .foregroundColor(.appTextPrimary)
                                }
                                Divider().background(Color.appDivider)
                                VendorFormField(label: "Price (Rp)", icon: "banknote") {
                                    TextField("0", text: $price)
                                        .keyboardType(.decimalPad)
                                        .foregroundColor(.appTextPrimary)
                                }
                            }
                        }

                        VendorFormCard(title: "Inventory") {
                            Stepper(value: $quantity, in: 1...10000) {
                                HStack {
                                    Text("Available Quantity").foregroundColor(.appTextPrimary)
                                    Spacer()
                                    Text("\(quantity)").fontWeight(.bold).foregroundColor(.appAccent)
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

                        Button(action: addItem) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Item").fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(name.isEmpty || price.isEmpty ? Color.appAccent.opacity(0.4) : Color.appAccent)
                        .cornerRadius(14)
                        .disabled(name.isEmpty || price.isEmpty || isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Catalog Item")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.appAccent)
                }
            }
        }
    }

    private func addItem() {
        guard let priceDouble = Double(price), let userId = authManager.currentUser?.id else { return }

        guard priceDouble > 0 else {
            errorMessage = "Price must be greater than Rp 0"
            return
        }

        isLoading = true
        let catalog = VendorCatalog(
            id: UUID().uuidString,
            vendorId: userId,
            catalogId: UUID().uuidString,
            name: name,
            description: description,
            price: priceDouble,
            quantity: quantity,
            createdAt: Date()
        )

        viewModel.addCatalogItem(catalog: catalog) { success, error in
            isLoading = false
            if success { dismiss() }
            else { errorMessage = error ?? "Failed to add item" }
        }
    }
}

// Reusable form cards specific to vendor views
struct VendorFormCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(.caption, design: .rounded)).fontWeight(.semibold).foregroundColor(.appTextSecondary).padding(.horizontal, 4)
            VStack { content }.padding().background(Color.appCard).cornerRadius(14)
        }
    }
}

struct VendorFormField<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: Content
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(.appAccent).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundColor(.appTextSecondary)
                content
            }
        }
    }
}

// MARK: - Catalog Item Detail

struct CatalogItemDetailView: View {
    let item: VendorCatalog

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    
                    // Header card
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.appDeep)

                        if let description = item.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.appDeep.opacity(0.8))
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appPrimary)
                    .cornerRadius(16)

                    // Details
                    VStack(spacing: 0) {
                        VendorDetailRow(label: "Price", value: FormattingHelper.formatCurrency(item.price))
                        Divider().background(Color.appDivider).padding(.leading, 16)
                        VendorDetailRow(label: "Available Quantity", value: "\(item.quantity)")
                        Divider().background(Color.appDivider).padding(.leading, 16)
                        VendorDetailRow(label: "Created", value: item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    .background(Color.appCard)
                    .cornerRadius(14)
                }
                .padding()
            }
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VendorDetailRow: View {
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

// MARK: - Invoices View

struct VendorInvoicesView: View {
    @ObservedObject var viewModel: VendorViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView().tint(.appAccent)
                            Text("Loading invoices...").font(.caption).foregroundColor(.appTextSecondary)
                        }
                        Spacer()
                    } else if viewModel.invoices.isEmpty {
                        Spacer()
                        VStack(spacing: 14) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 54))
                                .foregroundColor(.appAccent.opacity(0.5))
                            Text("No invoices found")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.invoices) { invoice in
                                    NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            HStack {
                                                Text("Invoice #\(invoice.id.prefix(8))")
                                                    .font(.system(.headline, design: .rounded))
                                                    .foregroundColor(.appTextPrimary)
                                                Spacer()
                                                Text(invoice.status.rawValue.capitalized)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(invoiceStatusColor(invoice.status).opacity(0.15))
                                                    .foregroundColor(invoiceStatusColor(invoice.status))
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
                                                    Image(systemName: "banknote.fill").foregroundColor(.appAccent)
                                                }
                                                Spacer()
                                                Label {
                                                    Text(invoice.dueDate.formatted(date: .abbreviated, time: .omitted))
                                                        .font(.caption)
                                                        .foregroundColor(.appTextSecondary)
                                                } icon: {
                                                    Image(systemName: "calendar").foregroundColor(.appAccent)
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
                }
            }
            .navigationTitle("Invoices")
        }
    }

    private func invoiceStatusColor(_ status: InvoiceStatus) -> Color {
        switch status {
        case .pending:   return .appAccent
        case .unpaid:    return .appOrange
        case .paid:      return .appGreen
        case .overdue:   return .appRed
        case .cancelled: return .appTextSecondary
        }
    }
}

// MARK: - Invoice Detail

struct InvoiceDetailView: View {
    @State var invoice: Invoice
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Header Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Invoice Record")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.appDeep)
                        
                        HStack {
                            Text("ID:")
                                .font(.caption)
                                .foregroundColor(.appDeep.opacity(0.7))
                            Text(invoice.id)
                                .font(.caption)
                                .monospaced()
                                .foregroundColor(.appDeep)
                        }
                        
                        HStack {
                            Text("Event ID:")
                                .font(.caption)
                                .foregroundColor(.appDeep.opacity(0.7))
                            Text(invoice.eventId)
                                .font(.caption)
                                .monospaced()
                                .foregroundColor(.appDeep)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appPrimary)
                    .cornerRadius(16)

                    // Details
                    VStack(spacing: 0) {
                        VendorDetailRow(label: "Amount", value: FormattingHelper.formatCurrency(invoice.amount))
                        Divider().background(Color.appDivider).padding(.leading, 16)
                        VendorDetailRow(label: "Status", value: invoice.status.rawValue.capitalized)
                        Divider().background(Color.appDivider).padding(.leading, 16)
                        VendorDetailRow(label: "Due Date", value: invoice.dueDate.formatted(date: .abbreviated, time: .omitted))
                        
                        if let paidAt = invoice.paidAt {
                            Divider().background(Color.appDivider).padding(.leading, 16)
                            VendorDetailRow(label: "Paid Date", value: paidAt.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                    .background(Color.appCard)
                    .cornerRadius(14)

                    // Notes if exist
                    if let notes = invoice.notes {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.appTextSecondary)
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.appTextPrimary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.appCard)
                        .cornerRadius(14)
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

                    // Accept Action
                    if invoice.status == .pending {
                        Button(action: acceptInvoice) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                    Text("Accept Invoice").fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                        .background(Color.appAccent)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .disabled(isLoading)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Invoice Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func acceptInvoice() {
        guard let vendorId = authManager.currentUser?.id else { return }
        isLoading = true
        errorMessage = ""

        FirebaseService.shared.updateInvoiceStatus(invoiceId: invoice.id, status: .unpaid) { success, error in
            isLoading = false
            if success { invoice.status = .unpaid }
            else { errorMessage = error ?? "Failed to accept invoice" }
        }
    }
}

// MARK: - Vendor Profile View

struct VendorProfileView: View {
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
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.appDeep)
                                )
                            Text(authManager.currentUser?.name ?? "Vendor Partner")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.appTextPrimary)
                            Text("Vendor")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.appGreen.opacity(0.15))
                                .foregroundColor(.appGreen)
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
            .navigationTitle("Vendor Profile")
        }
    }
}

#Preview {
    VendorMainView()
        .environmentObject(AuthManager())
}
