# Firebase Setup Checklist for Lifted App

## ✅ Already Completed in Code
- [x] Firebase Auth integration
- [x] Firestore service layer
- [x] User document creation on sign-up
- [x] Apple Sign-In support
- [x] Exercise seed data
- [x] Workout session tracking
- [x] Progression tracking
- [x] Personal records tracking

## 🔧 Required Setup Steps

### 1. Firebase Console Setup

#### A. Create/Configure Firebase Project
1. Go to https://console.firebase.google.com/
2. Create a new project or select existing project
3. Add an iOS app:
   - Click iOS icon
   - Enter your bundle ID (found in Xcode target settings)
   - Download `GoogleService-Info.plist`
   - **Important**: Add the plist file to your Xcode project root

#### B. Enable Authentication
1. Go to **Authentication** → **Sign-in method**
2. Enable **Email/Password**
3. Enable **Apple**:
   - Add your Apple Team ID
   - Configure your app's bundle ID in Apple Developer Portal
   - Enable "Sign in with Apple" capability

#### C. Enable Cloud Firestore
1. Go to **Firestore Database**
2. Click **Create database**
3. Choose **Test mode** for development (or Production mode if ready)
4. Select a region (choose closest to your users)
5. Click **Enable**

#### D. Set Up Security Rules
In Firestore → Rules, replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // All user subcollections
      match /{subcollection}/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Exercises - read-only for authenticated users
    match /exercises/{exerciseId} {
      allow read: if request.auth != null;
      allow write: if false; // Managed via console or admin
    }
  }
}
```

### 2. Xcode Configuration

#### A. Add Firebase Swift Packages
File → Add Package Dependencies → `https://github.com/firebase/firebase-ios-sdk`

**Required packages:**
- [x] FirebaseAuth
- [x] FirebaseCore
- [x] FirebaseFirestore
- [ ] FirebaseFirestoreSwift (optional but recommended)

#### B. Add Capabilities
Target → Signing & Capabilities → + Capability:
- [x] Sign in with Apple

#### C. Configure Info.plist (if needed)
Some Firebase features may require URL schemes. Check the Firebase setup guide if you encounter issues.

### 3. Initial Data Setup

#### Upload Exercise Library to Firestore

**Option 1: Using AdminSetupView (Recommended for Development)**

1. Temporarily add AdminSetupView to your app:
   ```swift
   // In your ContentView or main navigation
   .sheet(isPresented: $showAdminView) {
       AdminSetupView()
   }
   ```

2. Run the app and tap "Upload Exercises to Firestore"

3. Remove AdminSetupView after upload completes

**Option 2: Run Once in Code**

Add this to your app initialization (and remove after first run):
```swift
init() {
    FirebaseApp.configure()
    
    #if DEBUG
    // Uncomment to seed exercises (run once only!)
    // Task {
    //     try? await ExerciseSeedData.uploadToFirestore()
    // }
    #endif
}
```

**Option 3: Firebase Console (Manual)**

Upload exercises manually through the Firebase console → Firestore Database

### 4. Apple Developer Portal Configuration

For Sign in with Apple:
1. Go to https://developer.apple.com/
2. Certificates, Identifiers & Profiles
3. Select your App ID
4. Enable "Sign in with Apple" capability
5. Configure the service ID if needed

### 5. Testing Your Setup

#### Test Authentication:
- [ ] Sign up with email/password
- [ ] Sign in with email/password
- [ ] Sign out
- [ ] Password reset
- [ ] Sign in with Apple

#### Test Data Persistence:
- [ ] User profile saves and syncs
- [ ] Workout schedule persists
- [ ] Workout sessions save
- [ ] Exercise progressions track correctly
- [ ] Personal records save

#### Test Across Devices:
- [ ] Sign in on different devices
- [ ] Verify data syncs between devices
- [ ] Test offline behavior (data should cache locally)

### 6. Post-Setup Cleanup

#### Remove Test/Debug Code:
- [ ] Remove the test `Constants.swift` file (it has placeholder Firebase config)
- [ ] Remove AdminSetupView from production builds
- [ ] Remove any debug seed data calls

#### Security Hardening:
- [ ] Switch Firestore from test mode to production mode (after setting rules)
- [ ] Review and test security rules
- [ ] Add rate limiting if needed
- [ ] Consider adding Firebase App Check for additional security

### 7. Data Syncing Features Already Implemented

Your app already handles:
- ✅ User authentication state persistence
- ✅ Automatic user data fetching on login
- ✅ Workout session creation and updates
- ✅ Exercise progression tracking
- ✅ Personal record detection and saving
- ✅ Schedule management
- ✅ User preferences sync

All data operations use proper async/await patterns and are scoped to the authenticated user.

## 📊 Firestore Data Structure

Your app will create this structure in Firestore:

```
/users/{userId}
  - id, email, displayName, createdAt, preferences, onboardingCompleted

  /schedule/{scheduleId}
    - Workout schedules

  /progressionPlan/{planId}
    - Training progression plans

  /exerciseProgressions/{progressionId}
    - Per-exercise progression tracking

  /workoutSessions/{sessionId}
    - Completed and scheduled workouts

  /personalRecords/{recordId}
    - PR achievements

  /trainerNotes/{noteId}
    - Trainer notes and guidance

  /trainerChats/{chatId}
    - Trainer conversation history

/exercises/{exerciseId}
  - Exercise library (populated from seed data)
```

## 🐛 Troubleshooting

### "No such module 'FirebaseFirestore'"
- Verify Swift Package is added
- Clean build folder (Cmd+Shift+K)
- Restart Xcode

### "Firebase app not configured"
- Ensure `GoogleService-Info.plist` is in your project
- Verify `FirebaseApp.configure()` is called in app init

### "Permission denied"
- Check Firestore security rules
- Verify user is authenticated
- Check that userId matches authenticated user

### Data not syncing
- Check internet connection
- Verify Firestore is enabled in Firebase Console
- Check Xcode console for Firebase errors
- Verify user is authenticated before making Firestore calls

### Sign in with Apple not working
- Verify capability is enabled in Xcode
- Check bundle ID matches in Firebase and Apple Developer Portal
- Ensure Apple Team ID is configured in Firebase

## 🎉 You're Done!

Once you complete these steps, your app will:
- ✅ Authenticate users with email/password and Apple Sign-In
- ✅ Store user data in Firestore
- ✅ Sync data across devices automatically
- ✅ Track workouts, progressions, and PRs
- ✅ Work offline with local caching
- ✅ Maintain security with proper authentication and rules

Need help with any specific step? Let me know!
