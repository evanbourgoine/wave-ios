//
//  EditProfileView.swift
//  Wave
//
//  Edit user profile information
//

import SwiftUI

struct EditProfileView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var username: String = ""
    @State private var realName: String = ""
    @State private var bio: String = ""
    @State private var isSaving = false
    
    // Control whether to show navigation bar items (for sheet presentation)
    let isPresentedAsSheet: Bool
    
    init(isPresentedAsSheet: Bool = false) {
        self.isPresentedAsSheet = isPresentedAsSheet
    }
    
    var body: some View {
        Form {
            // Profile Picture Section
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            )
                        
                        Button(action: {
                            // TODO: Upload profile picture
                        }) {
                            Text("Change Photo")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
            
            // Basic Info Section
            Section {
                HStack {
                    Text("Username")
                        .frame(width: 100, alignment: .leading)
                    TextField("username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                HStack {
                    Text("Name")
                        .frame(width: 100, alignment: .leading)
                    TextField("Your Name", text: $realName)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bio")
                    TextEditor(text: $bio)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                }
            } header: {
                Text("Profile Information")
            } footer: {
                Text("This is how other users will see you on Wave")
                    .font(.caption)
            }
            
            // Account Info Section
            Section {
                HStack {
                    Text("Email")
                        .frame(width: 100, alignment: .leading)
                    Text(firebaseService.currentUser?.email ?? "")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Account")
            } footer: {
                Text("Email cannot be changed")
                    .font(.caption)
            }
            
            // Stats Section (Read-only)
            Section {
                HStack {
                    Text("Songs Played")
                        .frame(width: 140, alignment: .leading)
                    Spacer()
                    Text("\(firebaseService.currentUser?.totalSongsPlayed ?? 0)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Listening Hours")
                        .frame(width: 140, alignment: .leading)
                    Spacer()
                    Text("\(Int(firebaseService.currentUser?.totalListeningHours ?? 0))")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Member Since")
                        .frame(width: 140, alignment: .leading)
                    Spacer()
                    if let createdAt = firebaseService.currentUser?.createdAt {
                        Text(createdAt.formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Statistics")
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(isPresentedAsSheet ? .inline : .large)
        .toolbar {
            if isPresentedAsSheet {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    saveProfile()
                }) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(isSaving || !hasChanges)
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
    }
    
    // MARK: - Helper Functions
    
    private var hasChanges: Bool {
        username != (firebaseService.currentUser?.username ?? "") ||
        realName != (firebaseService.currentUser?.realName ?? "") ||
        bio != (firebaseService.currentUser?.bio ?? "")
    }
    
    private func loadCurrentProfile() {
        guard let user = firebaseService.currentUser else { return }
        username = user.username
        realName = user.realName ?? ""
        bio = user.bio ?? ""
    }
    
    private func saveProfile() {
        guard var user = firebaseService.currentUser else { return }
        
        isSaving = true
        
        // Update user object
        user.username = username
        user.realName = realName.isEmpty ? nil : realName
        user.bio = bio.isEmpty ? nil : bio
        user.updatedAt = Date()
        
        Task {
            do {
                try await firebaseService.updateUser(user)
                await MainActor.run {
                    isSaving = false
                    dismiss() // Dismiss immediately on success
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    print("❌ Error updating profile: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        EditProfileView(isPresentedAsSheet: true)
    }
}
