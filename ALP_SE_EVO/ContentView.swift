//
//  ContentView.swift
//  ALP_SE_EVO
//
//  Created by Anastasia on 14/05/26.
//

import SwiftUI

// MARK: - Login View

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showRegister = false
    @State private var isSeedingData = false
    @State private var seedMessage = ""
    @State private var seedSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("EVO")
                                .font(.system(size: 32, weight: .bold))
                            Text("Event Management System")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                        
                        // Form Card
                        VStack(spacing: 16) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                TextField("Enter your email", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                HStack {
                                    if showPassword {
                                        TextField("Enter your password", text: $password)
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                    }
                                    Button(action: { showPassword.toggle() }) {
                                        Text(showPassword ? "Hide" : "Show")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Error Message
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            // Login Button
                            Button(action: login) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Login")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity(isLoading || email.isEmpty || password.isEmpty ? 0.6 : 1)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                        
                        // Register Link
                        Button(action: { showRegister = true }) {
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundColor(.gray)
                                Text("Register")
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                        
                        // Demo Credentials & Seed Section
                        VStack(spacing: 12) {
                            Text("Demo Credentials")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                            
                            VStack(spacing: 6) {
                                Text("Peserta: peserta@evo.com / password")
                                Text("Panitia: panitia@evo.com / password")
                                Text("Vendor: vendor@evo.com / password")
                                Text("Admin: admin@evo.com / password")
                            }
                            .font(.caption2)
                            .foregroundColor(.gray)
                            
                            Divider()
                                .padding(.horizontal, 20)
                            
                            // Seed Demo Data Button
                            Button(action: seedDemoData) {
                                if isSeedingData {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Seeding data...")
                                            .font(.caption)
                                    }
                                } else {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.caption)
                                        Text("Seed Demo Data")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .foregroundColor(.blue)
                            .disabled(isSeedingData)
                            
                            if !seedMessage.isEmpty {
                                Text(seedMessage)
                                    .font(.caption2)
                                    .foregroundColor(seedSuccess ? .green : .red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                            }
                        }
                        .padding(12)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(20)
                }
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environmentObject(authManager)
        }
    }
    
    private func login() {
        errorMessage = ""
        isLoading = true
        authManager.login(email: email.trimmingCharacters(in: .whitespaces), password: password) { success, error in
            isLoading = false
            if !success {
                errorMessage = error ?? "Login failed"
            }
        }
    }
    
    private func seedDemoData() {
        isSeedingData = true
        seedMessage = ""
        authManager.seedDemoData { success, message in
            DispatchQueue.main.async {
                isSeedingData = false
                seedSuccess = success
                seedMessage = message
            }
        }
    }
}

// MARK: - Register View

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole: UserRole = .peserta
    @State private var showPassword = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    private let availableRoles: [UserRole] = [.peserta, .panitia, .vendor]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.system(size: 28, weight: .bold))
                            Text("Join the EVO platform")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        
                        // Form Card
                        VStack(spacing: 16) {
                            // Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                TextField("Enter your full name", text: $name)
                                    .textContentType(.name)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                TextField("Enter your email", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                HStack {
                                    if showPassword {
                                        TextField("Min. 6 characters", text: $password)
                                    } else {
                                        SecureField("Min. 6 characters", text: $password)
                                    }
                                    Button(action: { showPassword.toggle() }) {
                                        Text(showPassword ? "Hide" : "Show")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                SecureField("Re-enter your password", text: $confirmPassword)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // Role Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Register as")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Picker("Role", selection: $selectedRole) {
                                    ForEach(availableRoles, id: \.self) { role in
                                        Text(role.rawValue.capitalized).tag(role)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            // Error Message
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            // Register Button
                            Button(action: register) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Register")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .disabled(isFormIncomplete)
                            .opacity(isFormIncomplete ? 0.6 : 1)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                        
                        // Login Link
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .foregroundColor(.gray)
                                Text("Login")
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private var isFormIncomplete: Bool {
        isLoading || name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty
    }
    
    private func register() {
        errorMessage = ""
        
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter your name"
            return
        }
        guard trimmedEmail.isValidEmail() else {
            errorMessage = "Please enter a valid email address"
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        isLoading = true
        authManager.register(
            email: trimmedEmail,
            password: password,
            name: trimmedName,
            role: selectedRole
        ) { success, error in
            isLoading = false
            if success {
                dismiss()
            } else {
                errorMessage = error ?? "Registration failed"
            }
        }
    }
}

// MARK: - Preview Helpers

struct ContentView: View {
    var body: some View {
        LoginView()
            .environmentObject(AuthManager())
    }
}

#Preview {
    ContentView()
}
