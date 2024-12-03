//
//  Powerful_ReportsApp.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 17/11/2024.
//

import SwiftUI
import Firebase



@main
struct Powerful_ReportsApp: App {
    
    @StateObject private var viewModel = InspectionReportsViewModel()
    @State private var isActive = false
    
    init() {
        FirebaseApp.configure()
        
    }
    
    
    var body: some Scene {
        WindowGroup {
            
            if isActive {
                HomeView()
                    .environmentObject(viewModel)
            }else {
                SplashScreen(isActive: $isActive)
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
    @Binding var isActive: Bool
    var body: some View {
        VStack {
            VStack {
                Image("logo")
                    .font(.system(size: 60))
                    .clipShape(RoundedRectangle(cornerRadius:  20))
                 
                Text("Powerful Reports")
                    .font(.system(size: 20))
            }.scaleEffect(scale)
            .onAppear{
                withAnimation(.easeIn(duration: 0.7)) {
                    self.scale = 0.9
                }
            }
        }.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    self.isActive = true
                }
            }
        }
    }
}
