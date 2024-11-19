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
    
    init() {
        FirebaseApp.configure()
    }
    
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
