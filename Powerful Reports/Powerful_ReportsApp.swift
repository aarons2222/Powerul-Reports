//
//  Powerful_ReportsApp.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 17/11/2024.
//

import SwiftUI
import Firebase
import StoreKit

@main
struct Powerful_ReportsApp: App {
    @StateObject private var viewModel = InspectionReportsViewModel()
    @StateObject private var authModel = AuthenticationViewModel()
    @State private var isActive = false

    
    @State private var subscriptionStatusModel = SubscriptionStatusModel()
    @Environment(\.subscriptionIDs) private var subscriptionIDs
    @State private var status: EntitlementTaskState<SubscriptionStatus> = .loading
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authModel.isInitializing {
                    // Show loading state while auth is initializing
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else if isActive {
                    if authModel.user != nil {
                        HomeView()
                            .environmentObject(viewModel)
                            .environmentObject(authModel)
                            .environment(subscriptionStatusModel)
                        
                        
                            .subscriptionStatusTask(for: subscriptionIDs.group) { taskStatus in
                                self.status = await taskStatus.map { statuses in
                                    await ProductSubscription.shared.status(
                                        for: statuses,
                                        ids: subscriptionIDs
                                    )
                                }
                                switch self.status {
                                case .failure(let error):
                                    subscriptionStatusModel.subscriptionStatus = .notSubscribed
                                    print("Failed to check subscription status: \(error)")
                                case .success(let status):
                                    subscriptionStatusModel.subscriptionStatus = status
                                    print("Updated subscription status to: \(status)")
                                case .loading: break
                                @unknown default: break
                                }
                            }
                            .task {
                                ProductSubscription.createSharedInstance()
                                await ProductSubscription.shared.checkForUnfinishedTransactions()
                                await ProductSubscription.shared.observeTransactionUpdates()
                            }
                          
                    } else {
                        SignInWithApple()
                            .environmentObject(authModel)
                    }
                } else {
                    SplashScreen(isActive: $isActive)
                        .ignoresSafeArea()
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
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
