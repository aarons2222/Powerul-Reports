//
//  Powerful_ReportsApp.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 17/11/2024.
//

import SwiftUI
import Firebase
import FirebaseAuth

class AuthenticationModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage = ""
    
    


    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.errorMessage = ""
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.errorMessage = ""
            }
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
    }
}


@main
struct Powerful_ReportsApp: App {
    @StateObject private var viewModel = InspectionReportsViewModel()
    @StateObject private var authModel = AuthenticationModel()
    @State private var isActive = false
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if isActive {
                if authModel.isAuthenticated {
                    HomeView()
                        .environmentObject(viewModel)
                        .environmentObject(authModel)
                } else {
                    LoginRegView()
                        .environmentObject(authModel)
                }
            } else {
                SplashScreen(isActive: $isActive)
                    .ignoresSafeArea()
            }
        }
    }
}



extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}



struct SplashScreen: View {
    @State private var scale = 0.7
    @State private var opacity = 0.0
    @Binding var isActive: Bool
    
    // Cache the gradient to avoid recreating it
    private let gradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.color1.opacity(0.6),
            Color.color2.opacity(0.3),
            Color.white
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            // Use cached gradient
            gradient
                .ignoresSafeArea()
                .drawingGroup() // Use Metal for rendering
            
            // Optimize image loading and animation
            Image("logo_clear")
                .font(.system(size: 50))
                .opacity(opacity)
                .scaleEffect(scale)
                .drawingGroup() // Use Metal for rendering
        }
        .onAppear {
            withAnimation(.spring(
                response: 0.8,
                dampingFraction: 0.7
            )) {
                scale = 0.9
                opacity = 1.0
            }
            
            // Transition timing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isActive = true
                }
            }
        }
    }
}

