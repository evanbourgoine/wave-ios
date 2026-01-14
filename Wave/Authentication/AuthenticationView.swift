//
//  AuthenticationView.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/26/25.
//

//
//  AuthenticationView.swift
//  Wave
//
//  Sign in / Sign up view
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App Logo/Title
                VStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("Wave")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Your Music, Your Community")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Auth Form
                VStack(spacing: 20) {
                    if isSignUp {
                        // Username field (sign up only)
                        TextField("Username", text: $username)
                            .textFieldStyle(WaveTextFieldStyle())
                            .textContentType(.username)
                            .autocapitalization(.none)
                    }
                    
                    // Email field
                    TextField("Email", text: $email)
                        .textFieldStyle(WaveTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    // Password field
                    SecureField("Password", text: $password)
                        .textFieldStyle(WaveTextFieldStyle())
                        .textContentType(isSignUp ? .newPassword : .password)
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    // Submit button
                    Button(action: {
                        Task {
                            await handleAuth()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text(isSignUp ? "Create Account" : "Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                    .disabled(isLoading)
                    
                    // Toggle sign up/sign in
                    Button(action: {
                        withAnimation {
                            isSignUp.toggle()
                            errorMessage = nil
                        }
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
    }
    
    private func handleAuth() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        // Validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        if isSignUp && username.isEmpty {
            errorMessage = "Please enter a username"
            return
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        do {
            if isSignUp {
                _ = try await firebaseService.signUp(email: email, password: password, username: username)
            } else {
                try await firebaseService.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Custom Text Field Style

struct WaveTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .foregroundColor(.white)
            .accentColor(.white)
    }
}

#Preview {
    AuthenticationView()
}
