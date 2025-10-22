# GitHub Integration for GitLifting

## Overview
Complete GitHub OAuth authentication and workout logging system for GitLifting app.

## What Was Fixed

### 1. **Unreachable Catch Block Error**
**Problem:** In `GitHubRepositoryService.swift`, the `logWorkout()` method had a `do-catch` block trying to catch errors from a function that returns `Result<Void, Error>` instead of throwing.

**Solution:** Removed the unnecessary `do-catch` block since `createOrUpdateFile()` returns a `Result` type that doesn't throw.

```swift
// Before (unreachable catch):
do {
    let result = await createOrUpdateFile(...)
    return result
} catch {
    return .failure(error)  // Unreachable!
}

// After (fixed):
let result = await createOrUpdateFile(...)
return result
```

### 2. **Duplicate Info.plist Error**
**Problem:** Manual Info.plist file conflicted with Xcode's automatic generation.

**Solution:** 
- Deleted manual Info.plist
- Added URL scheme configuration to build settings using `INFOPLIST_KEY_CFBundleURLTypes`

## Architecture

### Services Layer

#### `GitHubAuthService.swift`
- Handles OAuth authentication flow
- Manages authentication state
- Fetches and caches user information
- Uses Apple's `ASWebAuthenticationSession` for secure auth

**Key Methods:**
- `authenticate()` - Initiates OAuth flow
- `signOut()` - Clears tokens and signs out user
- `fetchUserInfo()` - Gets current user's GitHub profile

#### `KeychainService.swift`
- Securely stores access tokens in iOS Keychain
- Provides CRUD operations for token management
- Uses device-only security (won't sync via iCloud)

**Key Methods:**
- `saveAccessToken(_:)` - Stores token securely
- `getAccessToken()` - Retrieves stored token
- `deleteAccessToken()` - Removes token from Keychain

#### `GitHubRepositoryService.swift`
- Manages GitHub repository operations
- Creates workout tracker repository
- Logs workouts as commits with markdown files

**Key Methods:**
- `createWorkoutRepository()` - Creates/verifies workout-tracker repo
- `logWorkout(workoutData:date:)` - Commits workout as markdown file
- `getRepository(name:)` - Fetches repository information

### Views Layer

#### `GitHubAuthView.swift`
- Beautiful, modern authentication UI
- Shows connected/disconnected states
- Displays user profile when authenticated
- Privacy-focused messaging

#### `ProfileView.swift` (Updated)
- Added GitHub integration section
- Shows connection status
- Quick access to authentication

### App Layer

#### `GitLiftingApp.swift` (Updated)
- Handles OAuth callback URLs via `.onOpenURL`
- Routes callbacks to `GitHubAuthService`
- Configured with custom URL scheme: `progressiontracker://`

## Configuration

### GitHub OAuth App Settings
- **Client ID:** `0v23ivLsewsXSLD10qj`
- **Client Secret:** `69a6f042d105c448358c4ab88e55a4355fcbf796`
- **Redirect URI:** `progressiontracker://oauth`
- **Scopes:** `public_repo`, `user:email` (minimal permissions for privacy)

### URL Scheme
Configured in project build settings:
```
INFOPLIST_KEY_CFBundleURLTypes = (
    {
        CFBundleTypeRole = Editor;
        CFBundleURLName = "com.progressiontracker.gitlifting";
        CFBundleURLSchemes = (progressiontracker,);
    },
);
```

## How to Use

### 1. **User Authentication**

```swift
// User taps "Connect to GitHub" in Profile
GitHubAuthService.shared.authenticate()

// Check authentication state
if GitHubAuthService.shared.isAuthenticated {
    print("User is logged in")
}

// Access current user
if let user = GitHubAuthService.shared.currentUser {
    print("Logged in as: \(user.login)")
}

// Sign out
GitHubAuthService.shared.signOut()
```

### 2. **Logging Workouts**

```swift
// Create workout log data
let workoutData = WorkoutLogData(
    programName: "Strong Lifts 5x5",
    dayName: "Day A",
    exercises: [
        ExerciseLogData(
            name: "Squat",
            sets: [
                SetLogData(weight: 100, reps: 5, unit: "kg"),
                SetLogData(weight: 100, reps: 5, unit: "kg"),
                SetLogData(weight: 100, reps: 5, unit: "kg")
            ]
        ),
        ExerciseLogData(
            name: "Bench Press",
            sets: [
                SetLogData(weight: 60, reps: 5, unit: "kg"),
                SetLogData(weight: 60, reps: 5, unit: "kg")
            ]
        )
    ]
)

// Log the workout
Task {
    let result = await GitHubRepositoryService.shared.logWorkout(
        workoutData: workoutData,
        date: Date()
    )
    
    switch result {
    case .success:
        print("Workout logged successfully!")
    case .failure(let error):
        print("Failed to log workout: \(error)")
    }
}
```

### 3. **Create Repository**

```swift
Task {
    let result = await GitHubRepositoryService.shared.createWorkoutRepository()
    
    switch result {
    case .success(let repo):
        print("Repository created: \(repo.htmlUrl)")
    case .failure(let error):
        print("Failed to create repository: \(error)")
    }
}
```

## Workout Log Format

Workouts are logged as markdown files in the `workouts/` directory:

```markdown
# Workout Log - October 21, 2025

## Program: Strong Lifts 5x5

### Day: Day A

## Exercises

### Squat

| Set | Weight | Reps |
|-----|--------|------|
| 1 | 100.0 kg | 5 |
| 2 | 100.0 kg | 5 |
| 3 | 100.0 kg | 5 |

### Bench Press

| Set | Weight | Reps |
|-----|--------|------|
| 1 | 60.0 kg | 5 |
| 2 | 60.0 kg | 5 |

---
*Logged automatically by GitLifting*
```

## Security Features

1. **Keychain Storage**: Tokens stored securely in iOS Keychain
2. **Device-Only**: Tokens won't sync across devices
3. **CSRF Protection**: Random state generation for OAuth
4. **Token Validation**: Automatic validation on app launch
5. **Secure Session**: Uses ASWebAuthenticationSession

## Error Handling

All services use Swift's `Result` type for error handling:

```swift
enum GitHubAuthError: Error {
    case invalidResponse
    case unauthorized
    case apiError(statusCode: Int)
    case tokenNotFound
}

enum GitHubRepositoryError: Error {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case userNotFound
    case fileNotFound
    case encodingError
}
```

## Testing Checklist

- [ ] Build project successfully (⌘B)
- [ ] Run app on device/simulator
- [ ] Navigate to Profile tab
- [ ] Tap "Connect to GitHub"
- [ ] Complete OAuth flow in Safari
- [ ] Verify callback returns to app
- [ ] Check user profile displays correctly
- [ ] Log a test workout
- [ ] Verify workout appears in GitHub repo
- [ ] Test sign out functionality
- [ ] Test authentication persistence (close/reopen app)

## Troubleshooting

### Build Errors
1. Clean build folder: `Product → Clean Build Folder (⇧⌘K)`
2. Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/ProgressionTracker-*`
3. Restart Xcode

### Authentication Issues
1. Verify GitHub OAuth app settings
2. Check redirect URI matches: `progressiontracker://oauth`
3. Confirm URL scheme is configured in build settings

### Token Issues
1. Check Keychain access
2. Verify token is being saved: `KeychainService.shared.hasAccessToken()`
3. Clear and re-authenticate if token is invalid

## File Structure

```
ProgressionTracker/
├── Services/
│   ├── GitHubAuthService.swift          # OAuth authentication
│   ├── KeychainService.swift            # Secure token storage
│   ├── GitHubRepositoryService.swift    # Repository operations
│   └── [existing services...]
├── Views/
│   ├── GitHubAuthView.swift             # Authentication UI
│   ├── ProfileView.swift                # Updated with GitHub integration
│   └── [existing views...]
├── Models/
│   └── [existing models...]
└── GitLiftingApp.swift                  # Updated with URL handling
```

## Next Steps

1. **Integration with Workout Completion:**
   - Hook up `GitHubRepositoryService.shared.logWorkout()` after workout completion
   - Add user preference for auto-logging
   - Show success/failure notifications

2. **Enhanced Features:**
   - View workout history from GitHub
   - Share workout links
   - Sync workout data from GitHub
   - Repository statistics and insights

3. **UI Improvements:**
   - Add sync status indicators
   - Show last sync time
   - Display GitHub contribution graph in app

## Support

For issues or questions:
1. Check this README
2. Review Xcode console logs
3. Verify GitHub OAuth app configuration
4. Check network connectivity

---

**Built with ❤️ for GitLifting**

