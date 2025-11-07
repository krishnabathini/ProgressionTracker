# ProgressionTracker (GitLifting)

A comprehensive iOS workout tracking application built with SwiftUI and SwiftData. This app helps users track their workout programs, log exercises, calculate progression recommendations, and optionally sync workout data to GitHub.

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Models](#models)
- [Views](#views)
- [Services](#services)
- [Core Application Files](#core-application-files)
- [Architecture](#architecture)

## Overview

ProgressionTracker is a fitness tracking app that allows users to:
- Create and manage workout programs with multiple workout days
- Track exercises and sets during workouts
- Get intelligent progression recommendations based on performance
- Sync workout logs to GitHub repositories
- Browse an exercise library with pre-populated exercises
- Track workout streaks and statistics

## Project Structure

```
ProgressionTracker/
├── Models/           # SwiftData model definitions
├── Views/            # SwiftUI view components
├── Services/         # Business logic and API services
├── ViewModels/       # (Currently empty)
└── Assets.xcassets/  # App icons and assets
```

## Models

### Exercise.swift
Represents an exercise template within a workout day. Each exercise has:
- **Purpose**: Defines exercise templates with target sets/reps for workout days
- **Key Properties**: `name`, `targetSets`, `targetReps`, `exerciseType` (upperBody/lowerBody)
- **Relationships**: Links to `WorkoutDay` and optionally `ExerciseLibraryItem`
- **Use Case**: Used when creating workout day templates and during workout tracking

### ExerciseLibrary.swift
Represents exercises available in the exercise library that users can browse and add to programs.
- **Purpose**: Provides a searchable library of exercises (default + custom)
- **Key Properties**: `name`, `category` (chest, back, legs, etc.), `type`, `isCustom`
- **Categories**: Chest, Back, Legs, Shoulders, Arms, Core
- **Use Case**: Users browse this library when adding exercises to workout days

### ExerciseSet.swift
Represents a single performed set within a workout session.
- **Purpose**: Tracks actual performance data for each set
- **Key Properties**: `setNumber`, `weight`, `reps`, `isCompleted`
- **Relationships**: Links to `WorkoutSession` and `Exercise`
- **Use Case**: Created when users log sets during a workout

### WorkoutDay.swift
Represents a specific day within a workout program (e.g., "Push Day", "Pull Day").
- **Purpose**: Organizes exercises into workout days within a program
- **Key Properties**: `name`, `orderIndex`
- **Relationships**: Links to `WorkoutProgram` and contains multiple `Exercise` items
- **Use Case**: Defines the structure of each day in a workout program

### WorkoutProgram.swift
Represents a complete workout program (e.g., "Push Pull Legs").
- **Purpose**: Top-level container for workout programs
- **Key Properties**: `name`, `createdDate`, `lastCompletedDayIndex`
- **Key Features**:
  - Rotation tracking (determines next workout day)
  - Streak calculation (tracks consecutive workout days)
  - Streak warnings (notifies when streak might break)
- **Relationships**: Contains multiple `WorkoutDay` and `WorkoutSession` items
- **Use Case**: Main container that users create and track

### WorkoutSession.swift
Represents a logged workout instance for a specific day/program.
- **Purpose**: Records completed workout sessions with date and notes
- **Key Properties**: `date`, `notes`
- **Relationships**: Links to `WorkoutProgram`, `WorkoutDay`, and contains multiple `ExerciseSet` items
- **Use Case**: Historical record of completed workouts

### Item.swift
Legacy SwiftData model from Xcode template - not actively used in the application.
- **Purpose**: Default model created by Xcode template
- **Note**: This file can likely be removed as it's not integrated into the app workflow

## Views

### ContentView.swift
Legacy SwiftUI view from Xcode template - not actively used.
- **Purpose**: Default view created by Xcode template
- **Note**: The app uses `ProgramListView` as the main entry point instead

### ProgramListView.swift
Main home screen displaying all workout programs.
- **Purpose**: Primary navigation hub showing all user's workout programs
- **Features**:
  - Displays list of all programs
  - Empty state when no programs exist
  - Create new program button
  - Program deletion with confirmation
  - Streak tracking display
- **Navigation**: Leads to `ProgramDetailView` for individual programs

### ProgramDetailView.swift
Detailed view for a specific workout program.
- **Purpose**: Shows program details and workout days
- **Features**: 
  - Displays all workout days in the program
  - Shows next workout day recommendation
  - Navigation to workout day details
  - Start workout functionality

### ProgramTemplateSelectionView.swift
Allows users to select from pre-made workout program templates.
- **Purpose**: Template selection screen when creating new programs
- **Templates**: Push Pull Legs, Upper Lower, Bro Split, Full Body
- **Functionality**: Creates new `WorkoutProgram` from selected template

### WorkoutDayDetailView.swift
Shows details of a specific workout day including all exercises.
- **Purpose**: Displays exercises for a workout day
- **Features**:
  - Lists all exercises in the day
  - Add/remove exercises
  - Start workout button
  - Exercise library integration

### ExerciseLibraryView.swift
Browseable and searchable exercise library.
- **Purpose**: Interface for finding and adding exercises
- **Features**:
  - Search functionality
  - Category filtering
  - Create custom exercises
  - Add exercises to workout days with target sets/reps configuration

### ExerciseTrackingView.swift
Main workout logging interface where users track sets during workouts.
- **Purpose**: Real-time workout tracking and set logging
- **Features**:
  - Log sets with weight and reps
  - Visual set completion tracking
  - Progression recommendations
  - Edit completed sets
  - Workout history display
  - Previous session metrics comparison
- **Key Functionality**: Creates `WorkoutSession` and `ExerciseSet` records

### EditSetView.swift
Modal view for editing a completed set.
- **Purpose**: Allows users to modify weight/reps after logging a set
- **Use Case**: Quick corrections during workout tracking

### WorkoutHistoryView.swift
Displays historical workout sessions.
- **Purpose**: Shows past completed workouts
- **Features**: 
  - Chronological workout list
  - Filter by program/day
  - View workout details

### WorkoutDateDetailView.swift
Shows details for a specific workout session on a particular date.
- **Purpose**: Detailed view of a past workout
- **Features**: Displays all exercises and sets from that session

### ProfileView.swift
User profile and statistics screen.
- **Purpose**: Displays user stats and GitHub integration settings
- **Features**:
  - Workout statistics (total workouts, weekly count)
  - GitHub authentication status
  - GitHub settings access
  - Workout history navigation

### GitHubAuthView.swift
OAuth authentication interface for GitHub.
- **Purpose**: Handles GitHub login flow
- **Features**:
  - OAuth authentication UI
  - Authentication status display
  - Sign out functionality

### GitHubSettingsView.swift
Configuration screen for GitHub integration.
- **Purpose**: Manage GitHub repository settings
- **Features**:
  - Repository name configuration
  - Auto-log workout toggle
  - Repository privacy settings

## Services

### ExerciseLibraryService.swift
Manages the exercise library including default exercises and custom user exercises.
- **Purpose**: Provides exercise library functionality
- **Key Functions**:
  - `populateDefaultExercises()`: Seeds database with default exercises
  - `searchExercises()`: Intelligent exercise search with exact/partial matching
  - `createCustomExercise()`: Creates user-defined exercises
- **Default Exercises**: Pre-populated with 40+ common exercises across all categories

### GitHubAuthService.swift
Manages GitHub OAuth authentication flow.
- **Purpose**: Handles GitHub OAuth authentication
- **Key Functions**:
  - `authenticate()`: Initiates OAuth flow
  - `signOut()`: Clears authentication
  - `fetchUserInfo()`: Gets authenticated user's GitHub profile
- **Security**: Stores tokens securely in Keychain
- **Scopes**: Requests `public_repo` and `user:email` scopes

### GitHubRepositoryService.swift
Handles GitHub repository operations for workout logging.
- **Purpose**: Creates and manages workout log repositories on GitHub
- **Key Functions**:
  - `createWorkoutRepository()`: Creates/verifies GitHub repository
  - `logWorkout()`: Logs workout data as markdown files in repository
  - `getRepository()`: Fetches repository information
- **Workout Format**: Converts workout data to markdown files stored in `workouts/` directory

### GitHubSettingsService.swift
Manages GitHub integration user preferences.
- **Purpose**: Stores and retrieves GitHub-related settings
- **Key Properties**:
  - `repositoryName`: Name of workout log repository
  - `isRepositoryPrivate`: Privacy setting (always public due to OAuth scope)
  - `autoLogWorkouts`: Auto-logging toggle
- **Storage**: Uses `UserDefaults` for persistence

### KeychainService.swift
Securely stores sensitive data (GitHub access tokens) in iOS Keychain.
- **Purpose**: Keychain wrapper for secure token storage
- **Key Functions**:
  - `saveAccessToken()`: Stores GitHub OAuth token
  - `getAccessToken()`: Retrieves stored token
  - `deleteAccessToken()`: Removes token on sign out
- **Security**: Uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for maximum security

### ModelDiagnosticService.swift
Development tool for diagnosing SwiftData model configuration.
- **Purpose**: Verifies all SwiftData models are properly configured
- **Key Functions**:
  - `performDiagnostics()`: Comprehensive model validation
  - `validateModelRelationships()`: Checks model relationships
  - `printSchemaInfo()`: Prints schema information
- **Use Case**: Debug builds only - helps catch model configuration issues

### ProgramTemplateService.swift
Manages workout program templates and creates programs from templates.
- **Purpose**: Provides pre-made workout program templates
- **Templates**:
  - Push Pull Legs (3 days)
  - Upper Lower (4 days)
  - Bro Split (5 days)
  - Full Body (3 days)
- **Key Functions**:
  - `createProgram()`: Creates `WorkoutProgram` from template
  - `getTemplateRecommendations()`: Returns usage recommendations
  - `getTrainingFrequency()`: Returns recommended frequency

### ProgressionCalculator.swift
Calculates progressive overload recommendations based on workout history.
- **Purpose**: Intelligent progression analysis engine
- **Key Functions**:
  - `shouldIncreaseWeight()`: Determines if weight should increase
  - `calculateNextWeight()`: Calculates recommended next weight
  - `getRecommendation()`: Returns user-friendly progression message
  - `getProgressionStatus()`: Returns progression status (ready/maintain/deload)
- **Logic**: 
  - Upper body: 2.5% increase increments
  - Lower body: 5% increase increments
  - Requires 3 sets meeting/exceeding target reps
  - Minimum meaningful increase: 2.5 lbs

## Core Application Files

### GitLiftingApp.swift
Main application entry point and SwiftUI app structure.
- **Purpose**: App lifecycle and SwiftData configuration
- **Key Responsibilities**:
  - Configures SwiftData model container with all models
  - Sets up navigation bar appearance (dark theme)
  - Handles OAuth callback URLs from GitHub
  - Initializes tab view (Programs, Profile)
  - Populates default exercises on app launch
- **Tab Structure**:
  - Programs tab: `ProgramListView`
  - Profile tab: `ProfileView`

## Architecture

### Data Layer
- **SwiftData**: Used for local data persistence
- **Models**: All data models use `@Model` macro for SwiftData integration
- **Relationships**: Properly configured inverse relationships for data integrity

### Authentication & Integration
- **OAuth Flow**: Uses `ASWebAuthenticationSession` for GitHub OAuth
- **Token Storage**: Secure Keychain storage via `KeychainService`
- **API Integration**: REST API calls to GitHub API v3

### Progression System
- **Calculator**: `ProgressionCalculator` analyzes workout history
- **Recommendations**: Provides intelligent weight progression suggestions
- **Validation**: Ensures meaningful weight increases (minimum 2.5 lbs)

### UI Architecture
- **SwiftUI**: Modern declarative UI framework
- **Navigation**: NavigationStack-based navigation
- **State Management**: `@State`, `@Query`, `@Published` for reactive updates
- **Theme**: Dark-themed UI with custom navigation bar styling

## Key Features

1. **Workout Program Management**: Create programs from templates or custom
2. **Exercise Library**: 40+ default exercises with search and categories
3. **Workout Tracking**: Real-time set logging with validation
4. **Progression Calculator**: AI-powered weight progression recommendations
5. **Streak Tracking**: Automatically tracks workout streaks
6. **GitHub Integration**: Optional workout logging to GitHub repositories
7. **Workout History**: View past workouts with detailed metrics

## Development Notes

- The `Item.swift` and `ContentView.swift` files are legacy Xcode template files and are not actively used
- The `ViewModels/` directory is currently empty - MVVM pattern could be implemented if needed
- All services use singleton pattern for shared state management
- Model diagnostics service is available in debug builds for troubleshooting



