# Wave Setup Guide 🚀

Quick setup guide to get Wave running on your machine.

## Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/wave-ios.git
cd wave-ios
```

## Step 2: Firebase Setup

### Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Name it "Wave" (or your preference)
4. Follow the setup wizard

### Add iOS App to Firebase

1. Click "Add App" → iOS
2. Enter your Bundle ID (e.g., `com.yourname.Wave`)
3. Download `GoogleService-Info.plist`
4. **IMPORTANT:** Place this file in the project root directory
5. **DO NOT** commit this file to Git (it's already in .gitignore)

### Enable Firebase Services

In Firebase Console:

1. **Authentication:**
   - Go to Authentication → Sign-in method
   - Enable "Email/Password"

2. **Firestore Database:**
   - Go to Firestore Database
   - Click "Create Database"
   - Start in production mode
   - Choose your location

3. **Security Rules** (temporarily open for development):
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

### Create Firebase Indexes

Go to Firestore → Indexes and create:

**Collection: `ratings`**
- Fields: `user_id` (Ascending), `item_type` (Ascending), `rating` (Descending)

**Collection: `pinned_items`**
- Fields: `user_id` (Ascending), `item_type` (Ascending), `pinned_at` (Descending)
- Fields: `user_id` (Ascending), `pinned_at` (Descending)

**Collection: `activities`**
- Fields: `user_id` (Ascending), `timestamp` (Descending)

## Step 3: Apple Developer Setup

### Apple Music API

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Navigate to Certificates, Identifiers & Profiles
3. Create an App ID
4. Enable "MusicKit" capability
5. Save

### Xcode Setup

1. Open `Wave.xcodeproj` in Xcode
2. Select the Wave target
3. Go to "Signing & Capabilities"
4. Select your Team
5. Click "+ Capability" and add "MusicKit"

## Step 4: Info.plist Configuration

Verify `Info.plist` contains:

```xml
<key>NSAppleMusicUsageDescription</key>
<string>Wave needs access to Apple Music to play songs and manage your library</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

## Step 5: Build Configuration

### Swift Package Dependencies

Xcode should automatically resolve these:
- Firebase iOS SDK
- FirebaseAuth
- FirebaseFirestore

If not, go to:
1. File → Add Package Dependencies
2. Add: `https://github.com/firebase/firebase-ios-sdk`
3. Select: FirebaseAuth, FirebaseFirestore

### Build Settings

1. Set deployment target to iOS 17.0+
2. Ensure Swift Language Version is 5.9+

## Step 6: Test Build

1. Select a device or simulator
2. Press Cmd+R to build and run
3. Sign up with email/password
4. Grant Apple Music permissions when prompted

## Step 7: Test Features

✅ **Sign In/Sign Up** - Create account
✅ **Apple Music Auth** - Grant access
✅ **Search** - Search for "Taylor Swift"
✅ **Profile** - View your profile
✅ **Ratings** - Rate an album (5 stars)
✅ **Pin** - Pin an artist to profile

## Troubleshooting

### "No such module 'Firebase'"
- Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Clean build folder: Shift+Cmd+K
- Rebuild: Cmd+B

### "GoogleService-Info.plist not found"
- Make sure file is in project root
- Check it's added to target membership in Xcode

### "MusicKit authorization failed"
- Check Info.plist has NSAppleMusicUsageDescription
- Verify MusicKit capability is enabled
- Reset app permissions in Settings

### "Firestore permission denied"
- Check Firebase security rules allow authenticated users
- Verify user is signed in
- Check Firebase console for errors

### Search/Playback not working
- Requires active Apple Music subscription
- Check device is connected to internet
- Try on real device (not simulator)

## Development Tips

- Use real device for best MusicKit performance
- Check console logs for detailed debugging
- Firebase data visible in Firebase Console
- Test with active Apple Music subscription

## Next Steps

- [ ] Customize app icon in Assets.xcassets
- [ ] Update README with your GitHub username
- [ ] Test on TestFlight with friends
- [ ] Submit to App Store (when ready)

---

Need help? Check the main README.md or open an issue!
