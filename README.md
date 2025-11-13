# ProgressionTracker (GitLifting)

A comprehensive iOS workout tracking application built with SwiftUI and SwiftData. This app helps users track their workout programs, log exercises, calculate progression recommendations, and optionally sync workout data to GitHub.

## 🛠️ Technologies & Tools

### Core Technologies
- **Swift 5.0+** - Primary programming language
- **SwiftUI** - Modern declarative UI framework for iOS
- **SwiftData** - Apple's modern data persistence framework (replacement for Core Data)
- **iOS 18.1+** - Target deployment platform

### Third-Party Services & APIs
- **Firebase** - Backend services integration
  - **Firebase Core** - Core Firebase functionality
  - **Firestore** - Cloud database for bug reports and data storage
- **GitHub API v3** - REST API integration for workout logging
- **Slack Webhooks** - Real-time bug report notifications

### iOS Frameworks & APIs
- **Foundation** - Core functionality and data structures
- **UIKit** - UI components and device information
- **Combine** - Reactive programming (via SwiftUI)
- **UserNotifications** - Local notification scheduling for streak reminders
- **ASWebAuthenticationSession** - OAuth authentication flow
- **Security/Keychain** - Secure token storage

### Development Tools
- **Xcode 16.1+** - IDE and development environment
- **Swift Package Manager** - Dependency management
- **Git** - Version control

### Architecture Patterns
- **MVVM** - Model-View-ViewModel (partially implemented)
- **Singleton Pattern** - Shared service instances
- **Repository Pattern** - Data access abstraction
- **Observer Pattern** - Reactive state management with `@Published` and `@State`

## 📁 Project Structure

```
ProgressionTracker/
├── Models/           # SwiftData model definitions
├── Views/            # SwiftUI view components
├── Services/         # Business logic and API services
├── ViewModels/       # (Currently empty - MVVM pattern ready)
└── Assets.xcassets/  # App icons and assets
```

## 📊 Models

### Exercise.swift
Represents an exercise template within a workout day.

**Purpose**: Defines exercise templates with target sets/reps for workout days

**Key Properties**:
- `name: String` - Exercise name
- `targetSets: Int` - Target number of sets
- `targetReps: Int` - Target number of reps per set
- `exerciseType: ExerciseType` - Enum: `.upperBody` or `.lowerBody`

**Relationships**: 
- Links to `WorkoutDay` (many-to-one)
- Optionally links to `ExerciseLibraryItem` (one-to-one)

**Use Case**: Used when creating workout day templates and during workout tracking

---

### ExerciseLibrary.swift
Represents exercises available in the exercise library that users can browse and add to programs.

**Purpose**: Provides a searchable library of exercises (default + custom)

**Key Properties**:
- `name: String` - Exercise name
- `category: ExerciseCategory` - Enum: `.chest`, `.back`, `.legs`, `.shoulders`, `.arms`, `.core`
- `type: ExerciseType` - Enum: `.upperBody` or `.lowerBody`
- `isCustom: Bool` - Whether exercise was created by user

**Categories**: Chest, Back, Legs, Shoulders, Arms, Core

**Use Case**: Users browse this library when adding exercises to workout days

---

### ExerciseSet.swift
Represents a single performed set within a workout session.

**Purpose**: Tracks actual performance data for each set

**Key Properties**:
- `setNumber: Int` - Set sequence number
- `weight: Double` - Weight used (in lbs)
- `reps: Int` - Repetitions performed
- `isCompleted: Bool` - Completion status

**Relationships**: 
- Links to `WorkoutSession` (many-to-one)
- Links to `Exercise` (many-to-one)

**Use Case**: Created when users log sets during a workout

---

### WorkoutDay.swift
Represents a specific day within a workout program (e.g., "Push Day", "Pull Day").

**Purpose**: Organizes exercises into workout days within a program

**Key Properties**:
- `name: String` - Day name (e.g., "Push Day")
- `orderIndex: Int` - Position in program rotation

**Relationships**: 
- Links to `WorkoutProgram` (many-to-one)
- Contains multiple `Exercise` items (one-to-many)

**Use Case**: Defines the structure of each day in a workout program

---

### WorkoutProgram.swift
Represents a complete workout program (e.g., "Push Pull Legs").

**Purpose**: Top-level container for workout programs

**Key Properties**:
- `name: String` - Program name
- `createdDate: Date` - Creation timestamp
- `lastCompletedDayIndex: Int?` - Tracks rotation progress

**Key Methods**:
- `nextWorkoutDay: WorkoutDay?` - Computed property determining next workout day
- `currentStreak: Int` - Computed property calculating consecutive workout days
- `streakWarningMessage: String?` - Computed property providing streak warnings

**Key Features**:
- Rotation tracking (determines next workout day)
- Streak calculation (tracks consecutive workout days)
- Streak warnings (notifies when streak might break)

**Relationships**: 
- Contains multiple `WorkoutDay` items (one-to-many)
- Contains multiple `WorkoutSession` items (one-to-many)

**Use Case**: Main container that users create and track

---

### WorkoutSession.swift
Represents a logged workout instance for a specific day/program.

**Purpose**: Records completed workout sessions with date and notes

**Key Properties**:
- `date: Date` - Session date
- `notes: String?` - Optional session notes

**Relationships**: 
- Links to `WorkoutProgram` (many-to-one, optional)
- Links to `WorkoutDay` (many-to-one, optional)
- Contains multiple `ExerciseSet` items (one-to-many)

**Use Case**: Historical record of completed workouts

---

## 🎨 Views

### ProgramListView.swift
Main home screen displaying all workout programs.

**Purpose**: Primary navigation hub showing all user's workout programs

**Key Features**:
- Displays list of all programs
- Empty state when no programs exist
- Create new program button
- Program deletion with confirmation
- Streak tracking display with fire emoji
- Custom navigation header

**Key Methods**:
- `confirmDelete(at:)` - Confirms deletion of a program
- `deleteProgram()` - Deletes the selected program from database

**Navigation**: Leads to `ProgramDetailView` for individual programs

---

### ProgramDetailView.swift
Detailed view for a specific workout program.

**Purpose**: Shows program details and workout days

**Key Features**: 
- Displays all workout days in the program
- Shows next workout day recommendation
- Navigation to workout day details
- Start workout functionality
- Skip workout day option
- Delete workout day with confirmation

**Key Methods**:
- `skipToNextWorkout()` - Advances to next workout day
- `confirmDeleteDay(_:)` - Confirms deletion of workout day
- `deleteDay(_:)` - Removes workout day from program

---

### ProgramTemplateSelectionView.swift
Allows users to select from pre-made workout program templates.

**Purpose**: Template selection screen when creating new programs

**Templates**: 
- Push Pull Legs (3 days)
- Upper Lower (4 days)
- Bro Split (5 days)
- Full Body (3 days)

**Key Methods**:
- `createProgramFromTemplate(_:)` - Creates `WorkoutProgram` from template
- `createCustomProgram()` - Creates custom program with user-entered name

**Functionality**: Creates new `WorkoutProgram` from selected template

---

### WorkoutDayDetailView.swift
Shows details of a specific workout day including all exercises.

**Purpose**: Displays exercises for a workout day

**Key Features**:
- Lists all exercises in the day
- Add/remove exercises
- Start workout button
- Exercise library integration
- Edit exercise targets (sets/reps)
- Complete workout functionality
- GitHub workout logging integration

**Key Methods**:
- `addExercise(_:)` - Adds exercise to workout day
- `removeExercise(_:)` - Removes exercise from workout day
- `completeWorkout()` - Marks workout as complete and logs to GitHub
- `saveExerciseTargets()` - Updates exercise target sets/reps

---

### ExerciseLibraryView.swift
Browseable and searchable exercise library.

**Purpose**: Interface for finding and adding exercises

**Key Features**:
- Search functionality with intelligent matching
- Category filtering (Chest, Back, Legs, Shoulders, Arms, Core)
- Create custom exercises
- Add exercises to workout days with target sets/reps configuration
- Shows both default and custom exercises

**Key Methods**:
- `searchExercises()` - Filters exercises based on search query
- `createCustomExercise()` - Creates user-defined exercise
- `addExerciseToWorkoutDay(_:)` - Adds selected exercise to workout day

---

### ExerciseTrackingView.swift
Main workout logging interface where users track sets during workouts.

**Purpose**: Real-time workout tracking and set logging

**Key Features**:
- Log sets with weight and reps
- Visual set completion tracking
- Progression recommendations with color-coded banners
- Edit completed sets
- Workout history display
- Previous session metrics comparison (volume, avg reps, lbs/rep)
- Volume metrics calculation
- Input validation for weight and reps
- Session management (finds or creates today's session)

**Key Methods**:
- `addSet()` - Creates and adds new set to workout
- `deleteSet(_:)` - Removes set from workout
- `updateRecommendation()` - Recalculates progression recommendation
- `findOrCreateSession()` - Locates or creates today's workout session
- `loadWorkoutHistory()` - Fetches previous workout sessions
- `updateVolumeMetrics()` - Calculates volume metrics for current session
- `getPreviousWorkoutMetrics()` - Retrieves metrics from previous session
- `getInitialRecommendation(for:sessions:)` - Generates initial recommendation for new exercises

---

### EditSetView.swift
Modal view for editing a completed set.

**Purpose**: Allows users to modify weight/reps after logging a set

**Key Features**:
- Edit weight and reps
- Save changes
- Cancel editing

**Use Case**: Quick corrections during workout tracking

---

### WorkoutHistoryView.swift
Displays historical workout sessions.

**Purpose**: Shows past completed workouts

**Key Features**: 
- Chronological workout list
- Filter by program/day
- View workout details
- Date-based organization

---

### WorkoutDateDetailView.swift
Shows details for a specific workout session on a particular date.

**Purpose**: Detailed view of a past workout

**Key Features**: 
- Displays all exercises and sets from that session
- Shows session notes
- Date and program information

---

### ProfileView.swift
User profile and statistics screen.

**Purpose**: Displays user stats and GitHub integration settings

**Key Features**:
- Workout statistics (total workouts, weekly count)
- GitHub authentication status
- GitHub settings access
- Workout history navigation
- Workout activity heatmap (GitHub-style)
- Report Bug button

**Key Methods**:
- `loadWorkoutDates()` - Fetches all workout dates for heatmap
- `workoutsThisWeek()` - Calculates workouts completed this week

---

### GitHubAuthView.swift
OAuth authentication interface for GitHub.

**Purpose**: Handles GitHub login flow

**Key Features**:
- OAuth authentication UI
- Authentication status display
- User profile information
- Sign out functionality
- Privacy-first messaging

---

### GitHubSettingsView.swift
Configuration screen for GitHub integration.

**Purpose**: Manage GitHub repository settings

**Key Features**:
- Repository name configuration
- Auto-log workout toggle
- Repository privacy settings
- View repository on GitHub
- Reset to defaults

**Key Methods**:
- `validateAndSaveRepoName()` - Validates and saves repository name

---

### BugReportView.swift
Interface for reporting bugs and issues.

**Purpose**: Allows users to submit bug reports

**Key Features**:
- Text editor for bug description
- Firestore integration for bug storage
- Slack notification integration
- Loading states during submission
- Error handling and user feedback
- Keyboard dismissal on tap

**Key Methods**:
- `submitBugReport()` - Submits bug report to Firestore and sends Slack notification

---

## 🔧 Services

### ExerciseLibraryService.swift
Manages the exercise library including default exercises and custom user exercises.

**Purpose**: Provides exercise library functionality

**Key Methods**:
- `populateDefaultExercises(modelContext:)` - Seeds database with default exercises (40+ exercises)
- `searchExercises(query:in:)` - Intelligent exercise search with exact/partial matching
- `createCustomExercise(name:category:type:modelContext:)` - Creates user-defined exercises
- `createDefaultExerciseList()` - Private method that returns array of default exercises

**Default Exercises**: Pre-populated with 40+ common exercises across all categories (Chest, Back, Legs, Shoulders, Arms, Core)

**Pattern**: Static methods (utility class)

---

### GitHubAuthService.swift
Manages GitHub OAuth authentication flow.

**Purpose**: Handles GitHub OAuth authentication

**Key Methods**:
- `authenticate()` - Initiates OAuth flow using `ASWebAuthenticationSession`
- `signOut()` - Clears authentication and removes tokens
- `fetchUserInfo()` - Gets authenticated user's GitHub profile information
- `handleOAuthCallback(url:)` - Processes OAuth callback URL

**Key Properties**:
- `isAuthenticated: Bool` - Published property indicating auth status
- `currentUser: GitHubUser?` - Published property with user info
- `authenticationError: String?` - Published property for error messages
- `isAuthenticating: Bool` - Published property for loading state

**Security**: Stores tokens securely in Keychain via `KeychainService`

**Scopes**: Requests `public_repo` and `user:email` scopes

**Pattern**: Singleton with `@Published` properties for reactive updates

---

### GitHubRepositoryService.swift
Handles GitHub repository operations for workout logging.

**Purpose**: Creates and manages workout log repositories on GitHub

**Key Methods**:
- `createWorkoutRepository(completion:)` - Creates/verifies GitHub repository
- `logWorkout(session:completion:)` - Logs workout data as markdown files in repository
- `getRepository(completion:)` - Fetches repository information
- `createFile(path:content:completion:)` - Creates file in repository via GitHub API
- `updateFile(path:content:sha:completion:)` - Updates existing file in repository

**Workout Format**: Converts workout data to markdown files stored in `workouts/` directory with date-based naming

**API Integration**: Uses GitHub REST API v3 with authenticated requests

**Pattern**: Singleton

---

### GitHubSettingsService.swift
Manages GitHub integration user preferences.

**Purpose**: Stores and retrieves GitHub-related settings

**Key Properties** (Published):
- `repositoryName: String` - Name of workout log repository (default: "workout-tracker")
- `isRepositoryPrivate: Bool` - Privacy setting (always false due to OAuth scope limitations)
- `autoLogWorkouts: Bool` - Auto-logging toggle

**Key Methods**:
- `resetToDefaults()` - Resets all settings to default values
- `isValidRepositoryName(_:)` - Validates repository name format

**Storage**: Uses `UserDefaults` for persistence

**Pattern**: ObservableObject with `@Published` properties

---

### KeychainService.swift
Securely stores sensitive data (GitHub access tokens) in iOS Keychain.

**Purpose**: Keychain wrapper for secure token storage

**Key Methods**:
- `saveAccessToken(_:)` - Stores GitHub OAuth token in Keychain
- `getAccessToken() -> String?` - Retrieves stored token
- `deleteAccessToken()` - Removes token on sign out

**Security**: Uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for maximum security

**Pattern**: Static utility class

---

### ModelDiagnosticService.swift
Development tool for diagnosing SwiftData model configuration.

**Purpose**: Verifies all SwiftData models are properly configured

**Key Methods**:
- `performDiagnostics()` - Comprehensive model validation
- `validateModelRelationships()` - Checks model relationships are properly configured
- `printSchemaInfo()` - Prints detailed schema information

**Use Case**: Debug builds only - helps catch model configuration issues early

**Pattern**: Static utility class

---

### ProgramTemplateService.swift
Manages workout program templates and creates programs from templates.

**Purpose**: Provides pre-made workout program templates

**Templates**:
- Push Pull Legs (3 days: Push Day, Pull Day, Leg Day)
- Upper Lower (4 days: Upper Body A, Lower Body A, Upper Body B, Lower Body B)
- Bro Split (5 days: Chest + Triceps, Back + Biceps, Shoulders, Legs, Arms)
- Full Body (3 days: Full Body A, Full Body B, Full Body C)

**Key Methods**:
- `createProgram(from:modelContext:)` - Creates `WorkoutProgram` from template
- `getTemplateRecommendations() -> [String: String]` - Returns usage recommendations for each template
- `getTrainingFrequency(for:) -> String` - Returns recommended training frequency

**Pattern**: Static utility class

---

### ProgressionCalculator.swift
Calculates progressive overload recommendations based on workout history.

**Purpose**: Intelligent progression analysis engine

**Key Methods**:
- `shouldIncreaseWeight(for:sessions:) -> Bool` - Determines if weight should increase based on most recent session
- `calculateNextWeight(currentWeight:exerciseType:) -> Double` - Calculates recommended next weight with meaningful increments
- `getRecommendation(for:currentWeight:sessions:) -> String` - Returns user-friendly progression message
- `getProgressionStatus(for:sessions:) -> ProgressionStatus` - Returns progression status enum (readyToProgress/maintain/needsDeload)
- `suggestInitialWeight(for:) -> Double` - Private method suggesting starting weight for new exercises

**Logic**: 
- Upper body: 2.5% increase increments (for weights 50+ lbs), flat 2.5 lbs for weights under 50 lbs
- Lower body: 5% increase increments (for weights 50+ lbs), flat 2.5 lbs for weights under 50 lbs
- Requires 3 sets meeting/exceeding target reps at same weight
- Minimum meaningful increase: 2.5 lbs
- Edge case handling: Prevents rounding issues that would result in no weight increase

**Pattern**: Utility class (can be instantiated or used statically)

---

### SlackNotificationService.swift
Sends bug report notifications to Slack via webhook.

**Purpose**: Real-time bug report notifications to development team

**Key Methods**:
- `sendBugReportNotification(description:)` - Sends formatted bug report to Slack channel

**Features**:
- Includes device metadata (app version, device model, iOS version, timestamp)
- Error handling for network failures
- HTTP status code validation

**Pattern**: Singleton

---

### StreakNotificationManager.swift
Schedules local notifications to help users preserve their workout streaks.

**Purpose**: Streak preservation through timely reminders

**Key Methods**:
- `requestNotificationPermissions()` - Requests user permission for local notifications
- `scheduleStreakNotifications(for:lastWorkoutDate:)` - Schedules streak preservation reminders
- `createNotificationRequest(identifier:title:body:triggerDate:)` - Private helper for creating notification requests

**Notification Types**:
- Day-before reminder (6 PM, day before streak deadline)
- Streak-ending reminder (6 PM on deadline day)

**Pattern**: Singleton

---

## 🚀 Core Application Files

### GitLiftingApp.swift
Main application entry point and SwiftUI app structure.

**Purpose**: App lifecycle and SwiftData configuration

**Key Responsibilities**:
- Configures SwiftData model container with all models
- Sets up navigation bar appearance (dark theme with custom colors)
- Handles OAuth callback URLs from GitHub
- Initializes tab view (Programs, Profile)
- Populates default exercises on app launch
- Firebase initialization via AppDelegate

**Key Components**:
- `AppDelegate` - Firebase configuration class
- `sharedModelContainer` - SwiftData model container with all models
- `handleOAuthCallback(_:)` - Processes GitHub OAuth callback URLs

**Tab Structure**:
- Programs tab: `ProgramListView`
- Profile tab: `ProfileView`

**Model Container**: Includes `WorkoutProgram`, `WorkoutDay`, `Exercise`, `WorkoutSession`, `ExerciseSet`, `ExerciseLibraryItem`

---

## 🏗️ Architecture

### Data Layer
- **SwiftData**: Used for local data persistence
- **Models**: All data models use `@Model` macro for SwiftData integration
- **Relationships**: Properly configured inverse relationships for data integrity
- **Firestore**: Cloud database for bug reports and analytics

### Authentication & Integration
- **OAuth Flow**: Uses `ASWebAuthenticationSession` for GitHub OAuth
- **Token Storage**: Secure Keychain storage via `KeychainService`
- **API Integration**: REST API calls to GitHub API v3
- **Webhooks**: Slack webhook integration for real-time notifications

### Progression System
- **Calculator**: `ProgressionCalculator` analyzes workout history
- **Recommendations**: Provides intelligent weight progression suggestions
- **Validation**: Ensures meaningful weight increases (minimum 2.5 lbs)
- **Edge Case Handling**: Prevents rounding issues that would prevent progression

### UI Architecture
- **SwiftUI**: Modern declarative UI framework
- **Navigation**: NavigationStack-based navigation
- **State Management**: `@State`, `@Query`, `@Published` for reactive updates
- **Theme**: Dark-themed UI with custom navigation bar styling
- **Custom Components**: Reusable UI components (StatCard, WorkoutHeatmap)

### Notification System
- **Local Notifications**: UserNotifications framework for streak reminders
- **Push Notifications**: Slack webhooks for bug reports
- **Permission Management**: Proper permission requests and handling

---

## ✨ Key Features

1. **Workout Program Management**: Create programs from templates or custom
2. **Exercise Library**: 40+ default exercises with search and categories
3. **Workout Tracking**: Real-time set logging with validation
4. **Progression Calculator**: Intelligent weight progression recommendations with edge case handling
5. **Streak Tracking**: Automatically tracks workout streaks with notifications
6. **GitHub Integration**: Optional workout logging to GitHub repositories
7. **Workout History**: View past workouts with detailed metrics
8. **Bug Reporting**: Integrated bug reporting with Firestore and Slack notifications
9. **Activity Heatmap**: GitHub-style workout activity visualization
10. **Volume Metrics**: Advanced metrics calculation (volume, avg reps, lbs/rep)

---

## 📝 Development Notes

- The `Item.swift` and `ContentView.swift` files are legacy Xcode template files and are not actively used
- The `ViewModels/` directory is currently empty - MVVM pattern could be implemented if needed
- All services use singleton pattern for shared state management
- Model diagnostics service is available in debug builds for troubleshooting
- Firebase integration requires `GoogleService-Info.plist` configuration file
- GitHub OAuth requires URL scheme configuration in Info.plist

---

## 🔐 Security Considerations

- OAuth tokens stored securely in iOS Keychain
- Keychain uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for maximum security
- GitHub OAuth uses minimal scopes (`public_repo`, `user:email`)
- No sensitive data stored in UserDefaults
- Firestore security rules should be configured for production use

---

## 📱 Platform Requirements

- **iOS**: 18.1+
- **Xcode**: 16.1+
- **Swift**: 5.0+
- **Device**: iPhone and iPad (Universal)

---

## 🎯 Future Enhancements

- MVVM pattern implementation for better separation of concerns
- Unit tests for progression calculator and services
- Widget support for quick workout logging
- Apple Watch companion app
- Social features for sharing workouts
- Advanced analytics and progress charts
