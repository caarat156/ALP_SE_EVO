import SwiftUI

struct VendorMainView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = VendorViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Catalog Tab
            VendorCatalogView(viewModel: viewModel)
                .tabItem {
                    Text("Catalog")
                }
                .tag(0)
                
            // Orders Tab
            VendorOrdersView(viewModel: viewModel)
                .tabItem {
                    Text("Orders")
                }
                .tag(1)
            
            // Invoices Tab
            VendorInvoicesView(viewModel: viewModel)
                .tabItem {
                    Text("Invoices")
                }
                .tag(2)
            
            // Profile Tab
            VendorProfileView()
                .tabItem {
                    Text("Profile")
                }
                .tag(3)
        }
        .onAppear {
            if let userId = authManager.currentUser?.id {
                viewModel.fetchCatalog(vendorId: userId)
                viewModel.fetchInvoices(vendorId: userId)
                viewModel.fetchEventOrders(vendorId: userId)
            }
        }
    }
}

struct VendorCatalogView: View {
    @ObservedObject var viewModel: VendorViewModel
    @EnvironmentObject var authManager: AuthManager
    @State private var showAddItem = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.catalogItems.isEmpty {
                    Text("No catalog items yet")
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(viewModel.catalogItems) { item in
                            NavigationLink(destination: CatalogItemDetailView(item: item)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                    HStack(spacing: 12) {
                                        Text(FormattingHelper.formatCurrency(Double(item.price)))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                        Text("Qty: \(item.quantity)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Button(action: { showAddItem = true }) {
                    Text("Add New Item")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                }
            }
            .navigationTitle("Catalog")
            .sheet(isPresented: $showAddItem) {
                AddCatalogItemView(viewModel: viewModel)
                    .environmentObject(authManager)
            }
        }
    }
}

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
            Form {
                Section(header: Text("Item Information")) {
                    TextField("Item Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("Price (Rp)", text: $price)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Quantity")) {
                    Stepper(value: $quantity, in: 1...1000) {
                        HStack {
                            Text("Available")
                            Spacer()
                            Text("\(quantity)")
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
                    Button(action: addItem) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Add Item")
                        }
                    }
                    .disabled(name.isEmpty || price.isEmpty || isLoading)
                }
            }
            .navigationTitle("Add Catalog Item")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addItem() {
        guard let priceDouble = Double(price), let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        let catalog = VendorCatalog(
            id: UUID().uuidString,
            vendorId: userId,
            catalogId: UUID().uuidString,
            name: name,
            description: description,
            price: Int(priceDouble),
            quantity: quantity,
            createdAt: Date()
        )
        
        viewModel.addCatalogItem(catalog: catalog) { success, error in
            isLoading = false
            if success {
                dismiss()
            } else {
                errorMessage = error ?? "Failed to add item"
            }
        }
    }
}

struct CatalogItemDetailView: View {
    let item: VendorCatalog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Price")
                    Spacer()
                    Text(FormattingHelper.formatCurrency(Double(item.price)))
                        .fontWeight(.semibold)
                        .font(.headline)
                }
                
                HStack {
                    Text("Available Quantity")
                    Spacer()
                    Text("\(item.quantity)")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Created")
                    Spacer()
                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
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
        .navigationTitle("Item Details")
    }
}

struct VendorInvoicesView: View {
    @ObservedObject var viewModel: VendorViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.invoices.isEmpty {
                    Text("No invoices yet")
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(viewModel.invoices) { invoice in
                            NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Invoice ID: \(invoice.id.prefix(8))")
                                            .font(.headline)
                                        Spacer()
                                        Text(invoice.status.rawValue.capitalized)
                                            .font(.caption)
                                            .padding(4)
                                            .background(statusColor(invoice.status).opacity(0.2))
                                            .foregroundColor(statusColor(invoice.status))
                                            .cornerRadius(4)
                                    }
                                    
                                    HStack {
                                        Text("Amount: \(FormattingHelper.formatCurrency(Double(invoice.amount)))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("Due: \(invoice.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Invoices")
        }
    }
    
    private func statusColor(_ status: InvoiceStatus) -> Color {
        switch status {
        case .unpaid:
            return .red
        case .paid:
            return .green
        case .cancelled:
            return .gray
        }
    }
}

struct InvoiceDetailView: View {
    let invoice: Invoice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Invoice Details")
                    .font(.headline)
                
                HStack {
                    Text("Invoice ID:")
                    Spacer()
                    Text(invoice.id.prefix(8))
                        .font(.caption)
                        .monospaced()
                }
                
                HStack {
                    Text("Event Name:")
                    Spacer()
                    Text(invoice.eventTitle)
                        .font(.caption)
                }
                
                HStack {
                    Text("Product Name:")
                    Spacer()
                    Text(invoice.catalogItemName)
                        .font(.caption)
                }
                
                HStack {
                    Text("Quantity:")
                    Spacer()
                    Text("\(invoice.quantity)")
                        .font(.caption)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(FormattingHelper.formatCurrency(Double(invoice.amount)))
                        .fontWeight(.semibold)
                        .font(.headline)
                }
                
                HStack {
                    Text("Status")
                    Spacer()
                    Text(invoice.status.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor(invoice.status))
                }
                
                HStack {
                    Text("Due Date")
                    Spacer()
                    Text(invoice.dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                }
                
                if let paidAt = invoice.paidAt {
                    HStack {
                        Text("Paid Date")
                        Spacer()
                        Text(paidAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                if let notes = invoice.notes {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Invoice Details")
    }
    
    private func statusColor(_ status: InvoiceStatus) -> Color {
        switch status {
        case .unpaid:
            return .red
        case .paid:
            return .green
        case .cancelled:
            return .gray
        }
    }
}

struct VendorProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Vendor Information")) {
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

// MARK: - Vendor Orders View
struct VendorOrdersView: View {
    @ObservedObject var viewModel: VendorViewModel
    @State private var selectedOrder: EventVendorItem?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.eventOrders.isEmpty {
                    Text("No orders yet")
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(viewModel.eventOrders) { order in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Event: \(order.eventTitle)")
                                        .font(.headline)
                                    Spacer()
                                    Text(order.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Text("Product: \(order.itemName)")
                                    .font(.subheadline)
                                
                                HStack {
                                    Text("Qty: \(order.quantity)")
                                        .font(.caption)
                                    Spacer()
                                    Text(FormattingHelper.formatCurrency(Double(order.itemPrice * order.quantity)))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                                
                                Button(action: {
                                    selectedOrder = order
                                }) {
                                    Text("Create Invoice")
                                        .font(.caption)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Event Orders")
            .sheet(item: $selectedOrder) { order in
                CreateInvoiceView(viewModel: viewModel, order: order)
            }
        }
    }
}

// MARK: - Create Invoice View
struct CreateInvoiceView: View {
    @ObservedObject var viewModel: VendorViewModel
    let order: EventVendorItem
    @Environment(\.dismiss) var dismiss
    
    @State private var notes = ""
    @State private var dueDate = Date().addingTimeInterval(86400 * 7) // Default 7 days
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Order Details")) {
                    HStack {
                        Text("Event")
                        Spacer()
                        Text(order.eventTitle)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Product")
                        Spacer()
                        Text(order.itemName)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Quantity")
                        Spacer()
                        Text("\(order.quantity)")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Total Amount")
                        Spacer()
                        Text(FormattingHelper.formatCurrency(Double(order.itemPrice * order.quantity)))
                            .fontWeight(.semibold)
                    }
                }
                
                Section(header: Text("Invoice Settings")) {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .overlay(
                            Text(notes.isEmpty ? "Additional notes (optional)" : "")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false),
                            alignment: .topLeading
                        )
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: createInvoice) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Send Invoice")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("New Invoice")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func createInvoice() {
        isLoading = true
        let totalAmount = order.itemPrice * order.quantity
        
        let invoice = Invoice(
            id: UUID().uuidString,
            eventId: order.eventId,
            vendorId: order.vendorId,
            eventTitle: order.eventTitle,
            vendorName: order.vendorName,
            catalogItemName: order.itemName,
            amount: totalAmount,
            quantity: order.quantity,
            status: .unpaid,
            dueDate: dueDate,
            createdAt: Date(),
            notes: notes.isEmpty ? nil : notes
        )
        
        viewModel.createInvoice(invoice: invoice) { success, error in
            isLoading = false
            if success {
                dismiss()
            } else {
                errorMessage = error ?? "Failed to create invoice"
            }
        }
    }
}

#Preview {
    VendorMainView()
        .environmentObject(AuthManager())
}
