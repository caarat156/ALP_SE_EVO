//
//  ALP_SE_EVOApp.swift
//  ALP_SE_EVO
//
//  Created by Anastasia on 14/05/26.
//

import SwiftUI
import Firebase

@main
struct ALP_SE_EVOApp: App {
    @StateObject var authManager = AuthManager()
    @StateObject var navigationManager = NavigationManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isLoggedIn {
                    // Main app based on user role
                    switch authManager.currentUser?.role {
                    case .peserta:
                        PesertaMainView()
                            .environmentObject(authManager)
                            .environmentObject(navigationManager)
                    case .panitia:
                        PanitiaMainView()
                            .environmentObject(authManager)
                            .environmentObject(navigationManager)
                    case .vendor:
                        VendorMainView()
                            .environmentObject(authManager)
                            .environmentObject(navigationManager)
                    case .admin:
                        AdminMainView()
                            .environmentObject(authManager)
                            .environmentObject(navigationManager)
                    case .none:
                        LoginView()
                            .environmentObject(authManager)
                    }
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
        }
    }
}
