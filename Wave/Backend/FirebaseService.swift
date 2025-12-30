//
//  FirebaseService.swift
//  Wave
//
//  Firebase database service for user data management
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        // Check if user is already signed in
        if let firebaseUser = Auth.auth().currentUser {
            Task {
                await loadUser(userId: firebaseUser.uid)
            }
        }
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, username: String) async throws -> User {
        // Create Firebase auth user
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Create User document
        let newUser = User(
            id: authResult.user.uid,
            username: username,
            email: email
        )
        
        try await saveUser(newUser)
        
        await MainActor.run {
            self.currentUser = newUser
            self.isAuthenticated = true
        }
        
        return newUser
    }
    
    func signIn(email: String, password: String) async throws {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        await loadUser(userId: authResult.user.uid)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - User Management
    
    func loadUser(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let user = try? document.data(as: User.self) {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            print("❌ Error loading user: \(error.localizedDescription)")
        }
    }
    
    func saveUser(_ user: User) async throws {
        guard let userId = user.id else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID is nil"])
        }
        
        try db.collection("users").document(userId).setData(from: user)
    }
    
    func updateUser(_ user: User) async throws {
        var updatedUser = user
        updatedUser.updatedAt = Date()
        try await saveUser(updatedUser)
        self.currentUser = updatedUser
    }
    
    // MARK: - Activity Management
    
    func logActivity(_ activity: Activity) async throws {
        try db.collection("activities").addDocument(from: activity)
    }
    
    func getRecentActivities(userId: String, limit: Int = 20) async throws -> [Activity] {
        let snapshot = try await db.collection("activities")
            .whereField("user_id", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Activity.self) }
    }
    
    // MARK: - Rating Management
    
    func saveRating(_ rating: Rating) async throws {
        // Check if rating already exists for this item
        let existingRatings = try await db.collection("ratings")
            .whereField("user_id", isEqualTo: rating.userId)
            .whereField("item_id", isEqualTo: rating.itemId)
            .getDocuments()
        
        if let existingDoc = existingRatings.documents.first {
            // Update existing rating
            try db.collection("ratings").document(existingDoc.documentID).setData(from: rating)
        } else {
            // Create new rating
            try db.collection("ratings").addDocument(from: rating)
        }
    }
    
    func getRatings(userId: String, itemType: Rating.RatingItemType? = nil) async throws -> [Rating] {
        var query: Query = db.collection("ratings")
            .whereField("user_id", isEqualTo: userId)
        
        if let itemType = itemType {
            query = query.whereField("item_type", isEqualTo: itemType.rawValue)
        }
        
        let snapshot = try await query
            .order(by: "rating", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Rating.self) }
    }
    
    func getTopRatings(userId: String, itemType: Rating.RatingItemType, limit: Int = 5) async throws -> [Rating] {
        let snapshot = try await db.collection("ratings")
            .whereField("user_id", isEqualTo: userId)
            .whereField("item_type", isEqualTo: itemType.rawValue)
            .order(by: "rating", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Rating.self) }
    }
    
    // MARK: - Pinned Items Management
    
    func pinItem(_ item: PinnedItem) async throws {
        try db.collection("pinned_items").addDocument(from: item)
    }
    
    func unpinItem(itemId: String, userId: String) async throws {
        let snapshot = try await db.collection("pinned_items")
            .whereField("user_id", isEqualTo: userId)
            .whereField("item_id", isEqualTo: itemId)
            .getDocuments()
        
        for document in snapshot.documents {
            try await db.collection("pinned_items").document(document.documentID).delete()
        }
    }
    
    func getPinnedItems(userId: String, itemType: PinnedItem.PinnedItemType? = nil) async throws -> [PinnedItem] {
        var query: Query = db.collection("pinned_items")
            .whereField("user_id", isEqualTo: userId)
        
        if let itemType = itemType {
            query = query.whereField("item_type", isEqualTo: itemType.rawValue)
        }
        
        let snapshot = try await query
            .order(by: "pinned_at", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: PinnedItem.self) }
    }
    
    // MARK: - Top Artists Management
    
    func saveTopArtists(_ artists: [TopArtist]) async throws {
        let batch = db.batch()
        
        for artist in artists {
            let docRef = db.collection("top_artists").document()
            try batch.setData(from: artist, forDocument: docRef)
        }
        
        try await batch.commit()
    }
    
    func getTopArtists(userId: String, timePeriod: TopArtist.TimePeriod, limit: Int = 5) async throws -> [TopArtist] {
        let snapshot = try await db.collection("top_artists")
            .whereField("user_id", isEqualTo: userId)
            .whereField("time_period", isEqualTo: timePeriod.rawValue)
            .order(by: "ranking")
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: TopArtist.self) }
    }
    
    // MARK: - Friendship Management
    
    func sendFriendRequest(to friendId: String, friendUsername: String, friendProfilePictureURL: String?) async throws {
        guard let currentUserId = currentUser?.id else { return }
        
        let friendship = Friendship(
            userId: currentUserId,
            friendId: friendId,
            friendUsername: friendUsername,
            friendProfilePictureURL: friendProfilePictureURL,
            status: .pending,
            createdAt: Date()
        )
        
        try db.collection("friendships").addDocument(from: friendship)
    }
    
    func acceptFriendRequest(friendshipId: String) async throws {
        try await db.collection("friendships").document(friendshipId).updateData([
            "status": Friendship.FriendshipStatus.accepted.rawValue
        ])
    }
    
    func getFriends(userId: String) async throws -> [Friendship] {
        let snapshot = try await db.collection("friendships")
            .whereField("user_id", isEqualTo: userId)
            .whereField("status", isEqualTo: Friendship.FriendshipStatus.accepted.rawValue)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Friendship.self) }
    }
    
    // MARK: - Listening Stats Management
    
    func saveListeningStats(_ stats: UserListeningStats) async throws {
        // Find existing stats for this period
        let snapshot = try await db.collection("listening_stats")
            .whereField("user_id", isEqualTo: stats.userId)
            .whereField("time_period", isEqualTo: stats.timePeriod.rawValue)
            .getDocuments()
        
        if let existingDoc = snapshot.documents.first {
            try db.collection("listening_stats").document(existingDoc.documentID).setData(from: stats)
        } else {
            try db.collection("listening_stats").addDocument(from: stats)
        }
    }
    
    func getListeningStats(userId: String, timePeriod: TopArtist.TimePeriod) async throws -> UserListeningStats? {
        let snapshot = try await db.collection("listening_stats")
            .whereField("user_id", isEqualTo: userId)
            .whereField("time_period", isEqualTo: timePeriod.rawValue)
            .getDocuments()
        
        return snapshot.documents.first.flatMap { try? $0.data(as: UserListeningStats.self) }
    }
    
    // MARK: - Utility Functions
    
    func incrementSongPlay(userId: String) async throws {
        guard let user = currentUser else { return }
        var updatedUser = user
        updatedUser.totalSongsPlayed += 1
        try await updateUser(updatedUser)
    }
    
    func updateListeningHours(userId: String, additionalHours: Double) async throws {
        guard let user = currentUser else { return }
        var updatedUser = user
        updatedUser.totalListeningHours += additionalHours
        try await updateUser(updatedUser)
    }
}
