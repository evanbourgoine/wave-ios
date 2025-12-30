# Wave 🎵

A social music analytics iOS app that integrates with Apple Music to provide listening insights, ratings, and social features.

## 🎯 Features

### Music Integration
- ✅ Apple Music integration (MusicKit)
- ✅ Search for songs, albums, and artists
- ✅ Play music directly from the app
- ✅ View and play user playlists
- ✅ Mini player and full player interface

### Social Features
- ✅ Firebase authentication
- ✅ User profiles with Instagram-style layout
- ✅ Pin favorite artists to profile
- ✅ Rate songs, albums, and artists (5-star system)
- ✅ View top-rated content
- 🚧 Friends system (coming soon)
- 🚧 Activity feed (coming soon)
- 🚧 Direct messaging (backend ready)

### Analytics
- ✅ Track listening history
- ✅ View listening statistics
- ✅ Top artists tracking
- ✅ Unique artists count
- ✅ Total listening hours

### Profile Features
- ✅ Instagram-style swipeable tabs (Playlists, Pinned, Ratings, Stats)
- ✅ Edit profile (username, real name, bio)
- ✅ Dark/Light mode toggle
- ✅ Metrics display (ratings count, friends count)

## 🛠 Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Minimum iOS:** 17.0+
- **Architecture:** MVVM
- **Backend:** Firebase (Firestore, Authentication)
- **Music API:** Apple MusicKit
- **Package Manager:** Swift Package Manager (SPM)

## 📦 Dependencies

- Firebase iOS SDK
  - FirebaseAuth
  - FirebaseFirestore
- Apple MusicKit

## 🚀 Setup Instructions

### Prerequisites
1. Xcode 15.0+
2. iOS 17.0+ device or simulator
3. Apple Developer Account
4. Firebase Project
5. Apple Music API access

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/wave-ios.git
   cd wave-ios
   ```

2. **Add Firebase Configuration**
   - Download `GoogleService-Info.plist` from your Firebase Console
   - Add it to the project root (this file is gitignored)

3. **Configure Apple Music**
   - Enable MusicKit in your Apple Developer account
   - Add Music User Token in Xcode capabilities

4. **Install Dependencies**
   - Open `Wave.xcodeproj` in Xcode
   - Dependencies will be resolved automatically via SPM

5. **Update Info.plist**
   Add these keys if not present:
   ```xml
   <key>NSAppleMusicUsageDescription</key>
   <string>This app needs access to Apple Music to play songs</string>
   ```

6. **Build and Run**
   - Select your target device/simulator
   - Press Cmd+R to build and run

## 🔐 Environment Variables

The following files are **gitignored** and need to be created:

- `GoogleService-Info.plist` - Firebase configuration (download from Firebase Console)

## 📱 App Structure

```
Wave/
├── Models/              # Data models (Song, Artist, Album, User, Rating, etc.)
├── Views/               # SwiftUI views
│   ├── MainTabView.swift
│   ├── ProfileView.swift
│   ├── SearchDiscoverView.swift
│   ├── PlaylistDetailView.swift
│   ├── AlbumDetailView.swift
│   ├── ArtistProfileView.swift
│   ├── EditProfileView.swift
│   └── SettingsView.swift
├── Services/            # Business logic
│   ├── MusicKitService.swift
│   └── FirebaseService.swift
└── Assets.xcassets/     # Images and colors
```

## 🔥 Firebase Collections

### users
```javascript
{
  username: string,
  real_name: string?,
  email: string,
  bio: string?,
  profile_picture_url: string?,
  total_songs_played: number,
  unique_artists_count: number,
  total_listening_hours: number,
  created_at: timestamp,
  updated_at: timestamp
}
```

### ratings
```javascript
{
  user_id: string,
  item_id: string,
  item_type: "song" | "album" | "artist",
  item_title: string,
  item_subtitle: string,
  rating: number (1-5),
  rated_at: timestamp
}
```

### pinned_items
```javascript
{
  user_id: string,
  item_id: string,
  item_type: "song" | "album" | "artist",
  item_title: string,
  item_subtitle: string,
  artwork_url: string?,
  pinned_at: timestamp
}
```

### activities
```javascript
{
  user_id: string,
  activity_type: "played" | "rated" | "pinned",
  item_id: string,
  item_title: string,
  item_subtitle: string,
  timestamp: timestamp
}
```

## 📋 Firebase Composite Indexes

Required indexes (create in Firebase Console):

1. **ratings collection:**
   - `user_id` (Ascending) + `item_type` (Ascending) + `rating` (Descending)

2. **pinned_items collection:**
   - `user_id` (Ascending) + `item_type` (Ascending) + `pinned_at` (Descending)
   - `user_id` (Ascending) + `pinned_at` (Descending)

3. **activities collection:**
   - `user_id` (Ascending) + `timestamp` (Descending)

## 🎨 Design System

- **Primary Color:** Blue
- **Accent Color:** Purple
- **UI Style:** Glassmorphic with aurora gradients
- **Profile Layout:** Instagram-inspired
- **Dark Mode:** Full support

## 🐛 Known Issues

- Playlist playback may require debugging (search playback works)
- Search feature requires active Apple Music subscription
- Some features work better on real devices vs simulator

## 🚧 Roadmap

- [ ] Fix playlist playback
- [ ] Implement friends system
- [ ] Add activity feed
- [ ] Enable direct messaging
- [ ] Add Spotify integration
- [ ] Implement AI playlist generation
- [ ] Add push notifications
- [ ] Create TestFlight beta

## 📄 License

[Your License Here - e.g., MIT]

## 👨‍💻 Author

[Your Name]

## 🙏 Acknowledgments

- Apple MusicKit for music integration
- Firebase for backend services
- SwiftUI community for inspiration

---

**Note:** This app requires an active Apple Music subscription to play songs from the catalog.
