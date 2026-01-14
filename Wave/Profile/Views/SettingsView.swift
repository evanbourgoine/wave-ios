//
//  SettingsView.swift
//  Wave
//
//  Settings screen for app preferences and account management
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showSignOutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Appearance Section
                Section {
                    Toggle(isOn: $isDarkMode) {
                        HStack {
                            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                .foregroundColor(isDarkMode ? .purple : .orange)
                                .frame(width: 28)
                            Text("Dark Mode")
                        }
                    }
                    .tint(.blue)
                } header: {
                    Text("Appearance")
                }
                
                // Account Section
                Section {
                    // Account Info
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Account")
                                .font(.subheadline)
                            Text(firebaseService.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Edit Profile (placeholder)
                    NavigationLink(destination: EditProfileView(isPresentedAsSheet: false)) {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            Text("Edit Profile")
                        }
                    }
                } header: {
                    Text("Account")
                }
                
                // Privacy Section
                Section {
                    NavigationLink(destination: Text("Privacy Settings")) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.green)
                                .frame(width: 28)
                            Text("Privacy")
                        }
                    }
                    
                    NavigationLink(destination: Text("Notifications")) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.red)
                                .frame(width: 28)
                            Text("Notifications")
                        }
                    }
                } header: {
                    Text("Preferences")
                }
                
                // About Section
                Section {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 28)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: Text("Terms of Service")) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.gray)
                                .frame(width: 28)
                            Text("Terms of Service")
                        }
                    }
                    
                    NavigationLink(destination: Text("Privacy Policy")) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.purple)
                                .frame(width: 28)
                            Text("Privacy Policy")
                        }
                    }
                } header: {
                    Text("About")
                }
                
                // Sign Out Section
                Section {
                    Button(action: {
                        showSignOutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                                .frame(width: 28)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? firebaseService.signOut()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

#Preview {
    SettingsView()
}
