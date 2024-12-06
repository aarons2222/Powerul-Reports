//
//  LoginReg.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 04/12/2024.
//

import Foundation
import SwiftUI


struct LoginRegView: View {
    @EnvironmentObject var authModel: AuthenticationModel
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                
                HStack{
                    Image("logo_clear")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .drawingGroup()
                        .padding(20)
                    Spacer()
                }
                HStack{
                    
                    Text(isSignUp ? "Create Account" : "Welcome Back")
                        .font(.title)
                        .fontWeight(.regular)
                    Spacer()
                    
                }
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !authModel.errorMessage.isEmpty {
                    Text(authModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                
                Spacer()
                
                GlobalButton(title: isSignUp ? "Sign Up" : "Sign In") {
                    if isSignUp {
                        authModel.signUp(email: email, password: password)
                    } else {
                        authModel.signIn(email: email, password: password)
                    }
                }
            
                
                Button(action: {
                    isSignUp.toggle()
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }
}


